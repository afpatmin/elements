//  Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';

/// This gets called each time a tag is toggled on or off, param value is the value of the tag toggled
typedef void onTagChangeCallback(String value);
typedef void onClickCallback();

class Tag
{
  Tag(this._value, this._label, this._ratio, this._uniqueSelect, String tooltip, DivElement container, this._onChange)
  {
    _root = new DivElement();

    _content = new DivElement();
    _content.style.position = "relative";
    _content.style.textAlign = "center";

    _content.style.display = "flex";
    _content.style.flexDirection = "column";
    _content.style.justifyContent = "center";

    _root.style.userSelect = "none";
    _labelSpan.setInnerHtml(_label);
    if (tooltip != null) _labelSpan.title = tooltip;

    _content.append(_labelSpan);

    _root.append(_content);

    _root.className = "tag";
    _content.className = "tag_content";
    _labelSpan.className = "tag_label";

    container.append(_root);

    window.onResize.listen((_) => updateHeight());

    updateHeight();
  }

  void updateHeight()
  {
    if (_ratio != null)
    {
      dynamic width = _content.getBoundingClientRect().width;
      _content.style.height = (width.toDouble() * _ratio).toString() + "px";
    }
  }

  void toggleSelected()
  {
    if (!_disabled)
    {
      _selected = !_selected;
      if (_selected == true)
      {
        _content.classes.add("selected");
        if (_icon != null && _iconSelected != null)
        {
          _icon.classes.add("hidden");
          _iconSelected.classes.remove("hidden");
        }
      }
      else
      {
        _content.classes.remove("selected");
        if (_icon != null && _iconSelected != null)
        {
          _iconSelected.classes.add("hidden");
          _icon.classes.remove("hidden");
        }
      }
      /// If uniqueSelect is true, only trigger onchange when selected
      if (_onChange != null && (_uniqueSelect == false || (_uniqueSelect == true && _selected == true))) _onChange(_value);
    }
  }

  void set onClick(onClickCallback callback)
  {
    _root.onClick.listen((_) => callback());
  }

  String get value => _value;
  String get label => _label;
  bool get selected => _selected;
  void set selected(bool value)
  {
    bool previous = _selected;

    _selected = value;
    if (_selected == true)
    {
      _content.classes.add("selected");
      if (_icon != null && _iconSelected != null)
      {
        _icon.classes.add("hidden");
        _iconSelected.classes.remove("hidden");
      }
    }
    else
    {
      _content.classes.remove("selected");
      if (_icon != null && _iconSelected != null)
      {
        _iconSelected.classes.add("hidden");
        _icon.classes.remove("hidden");
      }
    }

    if ((_selected != previous) && _onChange != null && (_uniqueSelect == false || (_uniqueSelect == true && _selected == true)))
    {
      _onChange(_value);
    }
  }
  void set disabled(bool value)
  {
    _disabled = value;
    if (value == true)
    {
      _content.classes.add("disabled");
    }
    else
    {
      _content.classes.remove("disabled");
      _content.style.color = "";
    }
  }

  void setIconSrc(String src, [String src_selected = null])
  {
    if (src_selected == null) src_selected = src;

    if (_icon != null && _iconSelected != null)
    {
      _icon.src = src;
      _iconSelected.src = src_selected;
    }
    else
    {
      _icon = new ImageElement(src:src);
      _iconSelected = new ImageElement(src:src_selected);
      _icon.className = _iconSelected.className = "tag_icon";

      _content.children.insert(0, _iconSelected);
      _content.children.insert(0, _icon);
    }

    if (_selected)
    {
      _icon.classes.add("hidden");
      _iconSelected.classes.remove("hidden");
    }
    else
    {
      _iconSelected.classes.add("hidden");
      _icon.classes.remove("hidden");
    }

  }

  void set ratio(double value)
  {
    _ratio = value;
  }

  void set label(String label)
  {
    if (_labelSpan != null) _labelSpan.setInnerHtml(label);
    _label = label;
  }

  void set description(String description)
  {
    if (_descriptionSpan != null) _descriptionSpan.setInnerHtml(description);
    else
    {
      _descriptionSpan = new ParagraphElement();
      _descriptionSpan.className = "tag_description";
      _descriptionSpan.setInnerHtml(description);
      _content.append(_descriptionSpan);
    }
  }

  void set onChange(onTagChangeCallback function)
  {
    _onChange = function;
  }

  //DivElement get content => _content;

  void set contentClass(String classname)
  {
    _content.className = "tag_content " + classname;
  }

  void set rootClass(String classname)
  {
    _root.className = "tag " + classname;
  }

  bool get uniqueSelect => _uniqueSelect;

  bool _uniqueSelect;

  bool _selected = false;
  bool _disabled = false;
  final String _value;
  String _label;
  final SpanElement _labelSpan = new SpanElement();
  ParagraphElement _descriptionSpan;
  ImageElement _icon, _iconSelected;
  onTagChangeCallback _onChange;
  DivElement _root, _content;

  double _ratio;
}

class TagCloudElement
{
  TagCloudElement(List<String> tag_labels,
                  this._container,
                  {
                    List<String> tag_values : null,
                    List<String> tooltips : null,
                    bool unique_select : false,
                    bool required : false,
                    double ratio : null,
                    onTagChangeCallback onChange : null
                  }) : super()
  {
    if (_container == null) throw new ArgumentError.notNull("container");
    if (tag_values != null && tag_values.length != tag_labels.length) throw new StateError("options and values length mismatch");
    if (tooltips != null && tooltips.length != tag_labels.length) throw new StateError("options and tooltips length mismatch");

    _container.classes.add("tag-cloud");

    _tags = new List();
    for (int i = 0; i < tag_labels.length; i++)
    {
      String value = (tag_values == null) ? tag_labels[i] : tag_values[i];
      String tooltip = (tooltips == null) ? null : tooltips[i];

      Tag tag = new Tag(value, tag_labels[i], ratio, unique_select, tooltip, _container, onChange);
      _tags.add(tag);
    }

    _tags.forEach((Tag tag)
    {
      tag.onClick = () => toggleSelected(tag);
    });

    _required = required;
  }

  void updateTagHeights()
  {
    _tags.forEach((Tag tag) => tag.updateHeight());
  }

  void toggleSelected(Tag tag)
  {
    if (_disabled == false && tag.uniqueSelect == true) _reset();
    tag.toggleSelected();
  }

  Map<String, String> get pairs
  {
    Map<String, String> dataSet = new Map();
    return dataSet;
  }

  /// unselect all tags
  void _reset()
  {
    _tags.forEach((Tag tag) => tag.selected = false);
  }

  bool get valid => !(_required && value.isNotEmpty);

  /// Comma separated string (",, ")
  String get value
  {
    List<String> valueList = new List();

    _tags.forEach((Tag tag)
    {
      if (tag.selected) valueList.add(tag.value);
    });

    return valueList.join(",, ");
  }

  /// Set selected options based on value, comma separated string
  set value(String values_css)
  {
    _tags.forEach((Tag tag) => tag.selected = false);
    if (values_css == null) return;

    List<String> valueList = values_css.split(",, ");
    valueList.forEach((String value)
    {
      _tags.forEach((Tag tag)
      {
        if (tag.value == value) tag.selected = true;
      });
    });
  }

  List<Tag> get tags => _tags;
  DivElement get container => _container;
  bool get required => _required;
  set required(bool flag) => _required = flag;
  set disabled(bool flag)
  {
    _disabled = flag;
    _tags.forEach((Tag tag) => tag.disabled = flag);
  }

  set onChange(onTagChangeCallback function)
  {
    _tags.forEach((tag) => tag.onChange = function);
  }

  bool _required = false;
  bool _disabled = false;

  final DivElement _container;
  List<Tag> _tags;
}