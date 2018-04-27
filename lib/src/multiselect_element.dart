//  Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

/*
 * \brief Multiple select
 */
import 'dart:html';

typedef void callback(String value);

class MultiSelectElement
{
  MultiSelectElement(List<String> options, {List<String> values : null, String label : null, bool required : false, int max : -1,
                     Element container : null, callback onChange : null, callback on_option_click : null}) : super()
  {
    if (values != null && options.length != values.length) throw new StateError("options and values length mismatch");

    _required = required;
    _max = max;
    _onChange = onChange;
    _root = new DivElement();
    _root.className = "row collapse multi-select";
    _selectedOptionsContainer = new DivElement();
    _selectedOptionsContainer.className = "columns multi-select-selected-container";

    _onOptionClick = on_option_click;

    DivElement selectorCol = new DivElement();
    DivElement addButtonCol = new DivElement();
    selectorCol.className = "medium-10 columns";
    addButtonCol.className = "medium-2 columns";
    _options = new SelectElement();
    _addElement = new SpanElement();
    _addElement.className = "postfix clickable no-select";
    _addElement.setInnerHtml("Add");
    _addElement.onClick.listen(_addSelected);

    if (options != null)
    {
      if (values == null) options.forEach((String value) => addOption(value, value));
      else
      {
        for (int i = 0; i < options.length; i++)
        {
          addOption(options[i], values[i]);
        }
      }
    }

    if (label != null)
    {
      DivElement labelCol = new DivElement();
      labelCol.className = "columns";
      LabelElement labelElement = new LabelElement();
      labelElement.setInnerHtml(label);
      labelCol.append(labelElement);
      _root.append(labelCol);
    }


    selectorCol.append(_options);
    addButtonCol.append(_addElement);
    _root.append(selectorCol);
    _root.append(addButtonCol);
    _root.append(_selectedOptionsContainer);
    if (container != null) container.children.add(_root);
    _options.setCustomValidity("");
    if (_required && _selectedOptionsContainer.children.isEmpty) _options.setCustomValidity("input_valid_multiselect");
    if (_onChange != null) _onChange(value);
  }

  void addOption(String title, String value)
  {
    OptionElement option = new OptionElement();
    option.innerHtml = title;
    option.value = (value != null) ? value : title;

    _options.append(option);
  }

  void clearOptions([bool refresh_value = true])
  {
    _options.children.clear();
    if (refresh_value == true) options = null;
  }

  /// \brief Removes any values that aren't in the options
  void cleanValues()
  {
    List<String> values = value.split(",, ");
    List<String> validValues =[];
    _options.children.forEach((option)
    {
      final found = (values.firstWhere((value) => value == (option as OptionElement).value, orElse:() => null));
      if (found != null) validValues.add(found);
    });
    options = validValues.join(",, ");
  }

  void focus()
  {
    _options.focus();
  }

  Map<String, String> get pairs
  {
    Map<String, String> dataSet = new Map();
    _options.children.forEach((Element option) => dataSet[(option as OptionElement).value] = option.innerHtml);
    return dataSet;
  }

  void _addToSelected(String option, [bool trigger_on_change = true])
  {
    if (_max >= 0 && _selectedOptionsContainer.children.length >= _max) return;
    DivElement addedOption = new DivElement();
    addedOption.className = "added-option no-select";

    /// Throws state error if no option with this value is found
    OptionElement selectedOption = _options.options.firstWhere((OptionElement opt) => opt.innerHtml == option);

    addedOption.dataset["value"] = selectedOption.value;
    selectedOption.remove();
    SpanElement label = new SpanElement();
    label.innerHtml = option;
    Element close = new Element.tag("i");
    close.className = "fa fa-times-circle close";
    close.onClick.listen((_) => _unSelect(addedOption));
    addedOption.children.add(label);
    addedOption.children.add(close);
    _selectedOptionsContainer.append(addedOption);
    _options.setCustomValidity("");
    if (_onChange != null && trigger_on_change) _onChange(value);
    if (_onOptionClick != null)
    {
      label.classes.add("clickable");
      label.onClick.listen((_)
      {
        _onOptionClick(addedOption.dataset["value"]);
      });
    }
  }

  void _addSelected([Event e = null])
  {
    if (_options.disabled) return;
    if (_max >= 0 && _selectedOptionsContainer.children.length >= _max) return;
    if (_options.selectedIndex < 0) return;
    DivElement addedOption = new DivElement();
    addedOption.className = "added-option no-select";

    addedOption.dataset["value"] = _options.selectedOptions.first.value;
    SpanElement label = new SpanElement();
    label.innerHtml = _options.selectedOptions.first.innerHtml;

    Element close = new Element.tag("i");
    close.className = "fa fa-times-circle close";
    close.onClick.listen((_) => _unSelect(addedOption));

    addedOption.children.add(label);
    addedOption.children.add(close);
    _selectedOptionsContainer.append(addedOption);
    _options.selectedOptions.first.remove();

    _options.setCustomValidity("");
    if (_onChange != null) _onChange(value);
    if (_onOptionClick != null)
    {
      label.classes.add("clickable");
      label.onClick.listen((_)
      {
        _onOptionClick(addedOption.dataset["value"]);
      });
    }
  }

  /// un-selects the option and returns it to the select list
  void _unSelect(DivElement addedOption)
  {
    if (!_disabled)
    {
      OptionElement option = new OptionElement();
      option.innerHtml = addedOption.children.first.innerHtml;
      option.value = addedOption.dataset["value"];
      _options.children.add(option);
      _selectedOptionsContainer.children.remove(addedOption);
      if (_selectedOptionsContainer.children.isEmpty)
      {
        _options.setCustomValidity("");
        _options.setCustomValidity("input_valid_multiselect");
      }
      if (_onChange != null) _onChange(value);
    }
  }

  /// unSelect all options
  void _reset()
  {
    _selectedOptionsContainer.children.forEach((Element addedOption)
    {
      OptionElement option = new OptionElement();
      option.innerHtml = addedOption.children.first.innerHtml;
      option.value = addedOption.dataset["value"];
      _options.children.add(option);
    });
    _selectedOptionsContainer.children.clear();
    _options.setCustomValidity("");
    _options.setCustomValidity("input_valid_multiselect");
  }

  bool get valid => !(_required && _selectedOptionsContainer.children.isEmpty);

  /// Comma separated string (",, ")
  String get value
  {
    String values = "";
    _selectedOptionsContainer.children.forEach((Element e)
    {
      if (e.dataset.containsKey("value")) values += e.dataset["value"] + ",, ";
    });
    if (values.length > 3) values = values.substring(0, values.length - 3);
    return values;
  }

  void showAllOptions()
  {
    _hiddenOptions.forEach(_options.children.add);
    _hiddenOptions.clear();
  }

  void hideAllOptionsExcept(List<String> values)
  {
    showAllOptions();

    if (values != null)
    {
      _options.options.where((option) => !values.contains(option.value)).toList(growable: true).forEach((element)
      {
        _hiddenOptions.add(element);
        element.remove();
      });
    }
  }

  String nameOf(String value)
  {
    for (int i = 0; i < _options.children.length; i++)
    {
      OptionElement option = _options.children[i];
      if (option.value == value) return option.innerHtml;
    }
    return null;
  }

  String nameOfSelected(String value)
  {
    for (int i = 0; i < _selectedOptionsContainer.children.length; i++)
    {
      DivElement e = _selectedOptionsContainer.children[i];
      if (e.dataset.containsKey("value") && e.dataset["value"] == value) return e.children.first.innerHtml;
    }
    return null;
  }

  /// Set selected options based on value, comma separated string
  set value(String values_css)
  {
    if (values_css == null || values_css.isEmpty)
    {
      options = "";
      return;
    }

    List<String> valueList = values_css.split(",, ");
    List<String> nameList = new List();
    valueList.forEach((String value) => nameList.add(nameOf(value)));
    options = nameList.join(",, ");
  }

  /// Set selected options based on name, comma separated string
  set options(String options_css)
  {
    if (!_disabled)
    {
      _reset();
      if (options_css != null)
      {
        if (options_css.length > 3)
        {
          List<String> valueList = options_css.split(",, ");
          valueList.forEach((String value)
          {
            try
            {
              _addToSelected(value, false);
            }
            on StateError
            {
              print("multiselect error, missing value: $value");
            }
          });
        }
        else if (options_css != "") _addToSelected(options_css, false);
      }
      if (_onChange != null) _onChange(value);
    }
  }

  get required => _required;
  get id => _options.id;
  set required(bool flag) => _required = flag;
  set id(String id) => _options.id = id;
  set onChange(callback callback) => _onChange = callback;

  set disabled(bool flag)
  {
    _disabled = flag;
    if (_disabled == true)
    {
      _options.disabled = true;
      options = "";
    }
    else _options.disabled = false;
  }

  callback _onChange;
  callback _onOptionClick;
  bool _required = false;
  bool _disabled = false;
  SelectElement _options;
  SpanElement _addElement;
  DivElement _selectedOptionsContainer;
  DivElement _root;
  int _max;
  //List<String> _visibleValues = new List();


  List<OptionElement> _hiddenOptions = new List();

}