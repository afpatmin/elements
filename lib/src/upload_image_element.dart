//  Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

/*
 * \brief Html box letting users upload images to the server, and displaying preview
 */

library UploadImageElement;

import 'dart:html';
import 'package:cryptoutils/cryptoutils.dart' hide mirrors;
import 'element_base.dart';

typedef void onChangeImage();

/// \param DivElement root - follows foundation conventions (container should be a foundation column)
class UploadImageElement extends afElement
{
  UploadImageElement({DivElement container, String url : "../graphics/icon-circle.svg", String title : null, onChangeImage onChange : null}) : super()
  {
    if (container == null) throw new ArgumentError.notNull("container");

    int maxByteSize = 102400;   /// bytes
    int maxDimension = 1500;    /// pixels

    _onChange = onChange;
    _root = container;
    DivElement labelRow = new DivElement();
    _row = new DivElement();
    _title = new LabelElement();

    _root.classes.add("upload-image");
    _row.className = labelRow.className = "row";
    _title.className = "columns";

    if (title == null) _title.setInnerHtml("image"); //daLang.getExp("image").then(_title.setInnerHtml);
    else _title.setInnerHtml(title);
    //daLang.getExp(title).then(_title.setInnerHtml);


    _reader = new FileReader();
    _col = new DivElement();
    _thumbnail = new ImageElement();
    _file = new FileUploadInputElement();
    _file.accept = "image/*";

    _col.className = "medium-12 columns trigger";
    _thumbnail.src = url;
    _isRaw = false;
    _file.onChange.listen((_) async
    {
      if (_file.files.isNotEmpty)
      {
        /// verify this is .jpeg/.png/.bmp/.gif
        File f = _file.files.last;
        if (f.type == "image/jpeg" || f.type == "image/png" || f.type == "image/gif" || f.type == "image/bmp")
        {
          _reader.readAsDataUrl(_file.files.last);
        }
        else
        {
          throw new Exception("error_invalid_file");
          //daNotify.display(await daLang.getExp("error"), await daLang.getExp("error_invalid_file"));
        }
      }
    });

    _reader.onLoad.listen((Event e)
    {
      /// scale down the image
      ImageElement temp = new ImageElement();
      temp.src = _reader.result;

      CanvasElement canvas = null;

      /// make sure the image is not bigger than maxDimension x maxDimension pixels, if it is, scale down and maintain aspect ratio
      if (temp.width > maxDimension || temp.height > maxDimension)
      {
        double scaleFactor = (temp.width > temp.height) ? maxDimension.toDouble() / temp.width : maxDimension.toDouble() / temp.height;
        int scaledWidth = (temp.width * scaleFactor).toInt();
        int scaledHeight = (temp.height * scaleFactor).toInt();

        canvas = new CanvasElement(width:scaledWidth, height:scaledHeight);
        var context = canvas.context2D;
        context.imageSmoothingEnabled = false;
        context.drawImageScaledFromSource(temp, 0, 0, temp.width, temp.height, 0, 0, scaledWidth, scaledHeight);
      }
      else
      {
        canvas = new CanvasElement(width:temp.width, height:temp.height);
        var context = canvas.context2D;
        context.imageSmoothingEnabled = false;
        context.drawImage(temp, 0, 0);
      }

      /// make sure the image filesize <= 100kb
      int fileByteSize = maxByteSize + 1;
      double quality = 0.9;
      while (fileByteSize > maxByteSize && quality > 0.1)
      {
        _thumbnail.src = canvas.toDataUrl("image/jpeg", quality);
        List<int> bytes = CryptoUtils.base64StringToBytes(_thumbnail.src.substring("data:image/jpeg;base64,".length));
        _imageDataBase64 = CryptoUtils.bytesToBase64(bytes);
        fileByteSize = bytes.length;
        quality -= 0.1;
      }
      _isRaw = true;
      if (_onChange != null) _onChange();
    });
    _col.children.add(_thumbnail);
    _col.children.add(_file);
    _row.children.add(_col);

    labelRow.children.add(_title);
    _root.children.add(labelRow);
    _root.children.add(_row);
  }

  set src(String value) => _thumbnail.src = value;

  String get imageDataBase64 => _imageDataBase64;
  bool get isRaw => _isRaw;

  void set onChange(onChangeImage callback)
  {
    _onChange = callback;
  }


  DivElement _root;
  DivElement _row;
  LabelElement _title;
  onChangeImage _onChange;

  String _imageDataBase64;
  FileReader _reader;
  FileUploadInputElement _file;
  ImageElement _thumbnail;
  DivElement _col;
  bool _isRaw;
}

