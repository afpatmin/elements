//  Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

/*
 * \brief Collapsible box for storing hiding/showing other html elements.
 * Requires Foundation css framework (http://foundation.zurb.com/) to work properly.
 * In addition, the following css should be added before using collapsible elements
 *
   /* Collapsible ............................... */
   .collapsible { background-color:#eee; margin-top:10px !important; padding-top:5px !important; padding-bottom:10px !important; }
   .collapsible div.content { overflow:hidden; max-height:0; transition:max-height 0.5s ease; -webkit-transition:max-height 0.5s ease; -moz-transition:max-height 0.5s ease; -o-transition:max-height 0.5s ease; }
   .collapsible .toggle { cursor:pointer; margin:0 0.25em 0 0.5em; font-size:1em; transition:all 75ms; -webkit-transition:all 75ms; -moz-transition:all 75ms; -o-transition:all 75ms; }
   .collapsible .title { display:inline; }
 */
import 'dart:async';
import 'dart:html';
import 'element_base.dart';

typedef void onToggleCollapse(bool collapsed);

class CollapsibleElement extends afElement
{
  /// \param String title
  /// \param Element root
  CollapsibleElement(String title, Element root) : super()
  {
    if (root == null) throw new ArgumentError.notNull("root");
    _root = root;
    _root.classes.add("collapsible");
    _toggle = new Element.tag("i");
    _toggle.className = "toggle fa fa-plus";
    _title = new HeadingElement.h3();
    _title.innerHtml = title;
    _title.className = "title clickable";

    _content = new DivElement();
    _content.className = "content";

    _innerContent = new DivElement();
    /* make sure content height is affected by floating elements */
    _innerContent.style.display = "inline-block";
    _innerContent.style.width = "100%";

    /// move all rows from _root to _innerContent
    _innerContent.children = _root.children;
    _root.children.clear();

    _content.children.add(_innerContent);

    /// refresh content height onclick in case the user has changed something within (adding items in a multiselect for example)
    _content.onClick.listen((e)
    {
      /// compensate for delay of any child collapsible element
      new Timer(const Duration(milliseconds:400), () => refreshHeight());
    });
    window.onResize.listen((_) => refreshHeight());

    _root.children.add(_toggle);
    _root.children.add(_title);
    _root.children.add(_content);

    enabled = true;
    collapsed = true;
  }

  void add(Element e) => _innerContent.children.add(e);
  void clear() => _innerContent.children.clear();

  void refreshHeight()
  {
    if (!isEmpty && _collapsed == false) _content.style.maxHeight = _evaluateContentHeight();
  }

  void set enabled(bool flag)
  {
    if (_toggleListener != null) _toggleListener.cancel();
    if (_titleListener != null) _titleListener.cancel();

    _title.style.opacity = _toggle.style.opacity = "0.4";

    if (flag == true)
    {
      _toggleListener = _toggle.onClick.listen(_toggleCollapsed);
      _titleListener = _title.onClick.listen(_toggleCollapsed);
      _title.style.opacity = _toggle.style.opacity = "1";
    }
  }

  void set collapsed(bool flag)
  {
    if (flag == true)
    {
      _toggle.classes.remove("fa-minus");
      _toggle.classes.add("fa-plus");
      _content.style.maxHeight = "0";
    }
    else
    {
      _toggle.classes.remove("fa-plus");
      _toggle.classes.add("fa-minus");
      _content.style.maxHeight = _evaluateContentHeight();
    }
    _collapsed = flag;

    if (_onToggleCollapse != null) _onToggleCollapse(_collapsed);
  }

  set onToggleCollapse(onToggleCollapse callback) => _onToggleCollapse = callback;

  void set title(String title) => _title.setInnerHtml(title);

  bool get isEmpty => _innerContent.children.isEmpty;

  void _toggleCollapsed(Event e)
  {
    e.stopPropagation();

    if (_collapsed == true) /// previous state
    {
      _toggle.classes.remove("fa-plus");
      _toggle.classes.add("fa-minus");
      _content.style.maxHeight = _evaluateContentHeight();
    }
    else
    {
      _toggle.classes.remove("fa-minus");
      _toggle.classes.add("fa-plus");
      _content.style.maxHeight = "0";
    }
    _collapsed = !_collapsed;
  }

  String _evaluateContentHeight()
  {
    return _innerContent.getBoundingClientRect().height.toInt().toString() + "px";
  }

  onToggleCollapse _onToggleCollapse;
  DivElement get content => _content;
  bool _collapsed;
  StreamSubscription _toggleListener, _titleListener;
  Element _toggle, _root;
  HeadingElement _title;
  DivElement _content;
  DivElement _innerContent;
}