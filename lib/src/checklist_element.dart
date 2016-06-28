//  Copyright (c) 2015, BuyByMarcus LTD. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

/*
 * \brief Collapsible checklist with multiple levels
 */

import 'dart:html';

class CheckListElement
{
  CheckListElement(String title, Map<String, bool> data, {Element container : null}) : super()
  {
    /// [dynamic] : bool or Map<String, dynamic> (a bool value indicates a checkbox (checked/unchecked) and a Map indicates a sub checklist)
    _checkboxes = new List<CheckboxInputElement>();

    /// Create the top indicator ("check/uncheck all children"), and create the list containing all the checkboxes
    _root = container;
    LIElement top = new LIElement();
    Element topToggle = new Element.tag("i");
    _topCheck = new CheckboxInputElement();
    _topLabel = new LabelElement();
    _list = new UListElement();
    topToggle.className = "fa fa-arrow-down top";
    _root.className = _topLabel.className = "top";
    _topLabel.htmlFor = _topCheck.id = title;
    _topLabel.innerHtml = title;
    top.children.add(topToggle);
    top.children.add(_topCheck);
    top.children.add(_topLabel);
    top.children.add(_list);
    _root.children.add(top);

    /// make all sibling checkboxes have the same value as the master checkbox (recursively)
    _topCheck.onClick.listen((_)
    {
      setAllChecked(_topCheck.checked);
    });

    /// toggle show/hide functionality
    topToggle.onClick.listen(_toggleVisible);

    if (data != null) data.forEach((String key, bool value) => addCheckbox);
    _evaluateState();

    /// start collapsed
    _toggleVisible();

    if (container != null) container.children.add(_root);
  }

  void addCheckbox(String name, bool checked)
  {
    LIElement li = new LIElement();
    CheckboxInputElement check = new CheckboxInputElement();
    LabelElement label = new LabelElement();
    label.htmlFor = label.innerHtml = check.id = name;
    check.checked = checked;
    /// set the color of top label based on the state of all sibling checkboxes
    check.onClick.listen(_evaluateState);
    _checkboxes.add(check);
    li.children.add(check);
    li.children.add(label);
    _list.children.add(li);
    _evaluateState();
  }

  void _toggleVisible([Event e = null])
  {
    _root.children.forEach((child)
    {
      child.children.forEach((c)
      {
        if (c is UListElement || c is LIElement) c.style.display = (c.style.display == "none") ? "inherit" : "none";
        else if (c.className == "fa fa-arrow-down top") c.style.transform = (c.style.transform == "rotate(-90deg)") ? "rotate(0deg)" : "rotate(-90deg)";
      });
    });
  }

  void _evaluateState([Event e = null])
  {
    try
    {
      _checkboxes.firstWhere((CheckboxInputElement cb) => cb.checked);
      /// at least one is checked
      _topLabel.style.color = "#565";
      _topCheck.checked = true;

      /// see if all are checked
      try
      {
        _checkboxes.firstWhere((CheckboxInputElement cb) => !cb.checked);
      }
      on StateError
      {
        /// all are checked
        _topLabel.style.color = "#5c5";
      }
    }
    on StateError
    {
      /// none is checked
      _topLabel.style.color = "#a77";
      _topCheck.checked = false;
    }
  }

  void setChecked(String label, bool flag)
  {
    for (int i = 0; i < _checkboxes.length; i++)
    {
      if (_checkboxes[i].id == label)
      {
        _checkboxes[i].checked = flag;
      }
    }
    _evaluateState();
  }

  void setAllChecked(bool flag)
  {
    _topCheck.checked = flag;
    _checkboxes.forEach((CheckboxInputElement check)
    {
      check.checked = flag;
    });

    _evaluateState();
  }

  /// Returns a comma separated string containing the names of all checked boxes (not including the top check)
  String get value
  {
    String values = "";
    _checkboxes.forEach((CheckboxInputElement checkbox)
    {
      if (checkbox.checked)
      {
        values += checkbox.id + ",, ";
      }
    });
    /// remove last ",, "
    return (values.length > 3) ? values.substring(0, values.length - 3) : "";
  }


  /// Takes a comma separated string and sets all mentioned checkboxes to checked
  set value(String values)
  {
    setAllChecked(false);
    if (values != null && values.length > 3)
    {
      List<String> valueList = values.split(",, ");
      valueList.forEach((value)
      {
        setChecked(value, true);
      });
    }
  }


  /// Checkboxes that belong to this list only (not grandchildren etc)
  CheckboxInputElement _topCheck;
  LabelElement _topLabel;
  List<CheckboxInputElement> _checkboxes;
  UListElement _list;
  Element _root;
}