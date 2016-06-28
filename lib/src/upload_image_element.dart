//  Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
//  is governed by a BSD-style license that can be found in the LICENSE file.

/*
 * \brief Html box letting users upload images to the server, and displaying preview
 */

import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import 'package:cryptoutils/cryptoutils.dart' show CryptoUtils;

typedef void onChangeImage();

/// \param DivElement root - follows foundation conventions (container should be a foundation column)
class UploadImageElement
{
  UploadImageElement({DivElement container, String url : "../graphics/icon-circle.svg", String title : null, onChangeImage onChange : null}) : super()
  {
    if (container == null) throw new ArgumentError.notNull("container");

    _onChange = onChange;
    _root = container;
    DivElement labelRow = new DivElement();
    _row = new DivElement();
    _label = new LabelElement();
    _magnifyIcon = new Element.tag("i");
    _magnifyIcon.className = "fa fa-search-plus magnify";
    _magnifyIcon.onClick.listen(_magnify);

    window.onResize.listen((_)
    {
      if (_popupContainer != null) _popupContainer.remove();
    });

    _root.classes.add("upload-image");
    _row.className = labelRow.className = "row";
    _label.className = "columns upload_image_label";

    if (title == null) _label.setInnerHtml("image");
    else _label.setInnerHtml(title);

    _reader = new FileReader();
    _metaReader = new FileReader();
    _col = new DivElement();
    _thumbnail = new ImageElement();

    _file = new FileUploadInputElement();
    _file.accept = "image/*";
    _file.setAttribute("capture", "camera");

    _thumbnail.onClick.listen((_) => _file.click());
    _label.onClick.listen((_) => _file.click());

    _col.className = "medium-12 columns";
    _thumbnail.src = url;
    _thumbnail.className = "upload_image_thumbnail clickable";
    _isRaw = false;

    _file.onChange.listen((_) async
    {
      if (_file.files.isNotEmpty)
      {
        /// verify this is .jpeg/.png/.bmp/.gif
        File f = _file.files.last;
        /// JPG file - read EXIF metadata so that we can figure out image orientation and rotate accordingly
        if (f.type == "image/jpeg" || f.type == "image/jpg")
        {
          /// EXIF specifications states metadata will always be in the first 64kb of the file, we double it just in case.
          _metaReader.readAsArrayBuffer(f.slice(0, 131072));
        }
        /// Any other supported format, skip metadata
        else if (f.type == "image/png" || f.type == "image/gif" || f.type == "image/bmp") _reader.readAsDataUrl(f);
        else throw new Exception("error_invalid_file");
      }
    });

    _col.append(_magnifyIcon);
    _col.append(_thumbnail);
    _col.append(_file);
    _row.append(_col);

    labelRow.append(_label);
    _root.append(_row);
    _root.append(labelRow);

    _metaReader.onLoad.listen(_extractExifOrientationAndLoadImage);
    _reader.onLoad.listen(_generateScaledImage);
  }

  /// Loads image only after exif orientation has been extracted
  void _extractExifOrientationAndLoadImage(ProgressEvent e)
  {
    _orientation = 0;
    Uint8List buffer = new Uint8List(e.loaded); // 0-255
    buffer.setRange(0, e.loaded, _metaReader.result);

    ByteData byteData = new ByteData.view(buffer.buffer);

    int byteOffset = 2; // skip first two bytes (0xFF 0xD8) indicating this is is a jpg file

    while (byteOffset <= e.loaded)
    {
      /// First byte is always 0xFF and second byte (0x**) is always identifier of what comes next
      byteOffset += 1;
      int identifier = byteData.getUint8(byteOffset);
      byteOffset += 1;

      // Data ByteSize (including ByteSize info itself (+2 bytes))
      int dataByteSize = byteData.getUint16(byteOffset);
      byteOffset += 2;

      if (identifier == 225) /// 0xE1 - Exif Marker
      {
        List<int> exifIdentifier = [byteData.getUint8(byteOffset), byteData.getUint8(byteOffset+1), byteData.getUint8(byteOffset+2), byteData.getUint8(byteOffset+3)];
        String strExifIdentifier = ASCII.decode(exifIdentifier);
        if (strExifIdentifier == "Exif")
        {
          /// "Exif\0\0"
          byteOffset += 6;

          /// TIFF HEADER
          /// Endianess
          String strEndian = (ASCII.decode([byteData.getUint8(byteOffset), byteData.getUint8(byteOffset + 1)]));
          Endianness endian = (strEndian == "II") ? Endianness.LITTLE_ENDIAN : Endianness.BIG_ENDIAN;
          byteOffset += 2;

          /// Next two bytes are Always 0x2a00 (or 0x002a for big endian)
          byteOffset += 2;

          /// Offset to the first IDF (from exifStart)
          int offsetExifToIFD = byteData.getUint32(byteOffset, endian);
          byteOffset += offsetExifToIFD - 4;

          /*
          https://github.com/mayanklahiri/easyexif/blob/master/exif.cpp
          */
          /// Number of entries in this IFD
          int exifEntries = byteData.getUint16(byteOffset, endian);
          byteOffset += 2;

          for (int i = 0; i < exifEntries; i++)
          {
            /// Type
            int type = byteData.getUint16(byteOffset, endian);
            byteOffset += 2;

            /// Orientation
            if (type == 274)
            {
              /// data format (we know this is unsigned short
              byteOffset += 2;

              /// number of components (we know this is 1)
              byteOffset += 4;

              _orientation = byteData.getUint16(byteOffset, endian);
              byteOffset += 4;
            }
            else byteOffset += 10; /// 12 bytes per entry
          }
        }
        break;
      }
      byteOffset += dataByteSize - 2;
    }
    /// Done reading metadata, read actual image
    _reader.readAsDataUrl(_file.files.first);
  }

  void _generateScaledImage(ProgressEvent e)
  {
    /// Pad the base64 encoded data to become divisible by 4 to conform with iOS standards.
    String base64 = _reader.result.toString();
    if (base64.contains("data:image/jpeg;base64,"))
    {
      while ((base64.length - "data:image/jpeg;base64,".length) % 4 > 0) { base64 += '='; }
    }
    else if (base64.contains("data:image/jpg;base64,") || base64.contains("data:image/png;base64,") || base64.contains("data:image/gif;base64,") || base64.contains("data:image/bmp;base64,"))
    {
      while ((base64.length - "data:image/jpg;base64,".length) % 4 > 0) { base64 += '='; }
    }

    /// scale down the image
    ImageElement temp = new ImageElement();
    temp.src = base64;

    temp.onLoad.listen((_)
    {
      CanvasElement canvas = null;

      /// make sure the image is not bigger than maxDimension x maxDimension pixels, if it is, scale down and maintain aspect ratio
      if (temp.width > maxDimension || temp.height > maxDimension)
      {
        double scaleFactor = (temp.width > temp.height) ? maxDimension.toDouble() / temp.width : maxDimension.toDouble() / temp.height;
        int scaledWidth = (temp.width * scaleFactor).toInt();
        int scaledHeight = (temp.height * scaleFactor).toInt();

        canvas = new CanvasElement(width: scaledWidth, height: scaledHeight);
        CanvasRenderingContext2D context = canvas.context2D;
        _transformContextExifOrientation(canvas, _orientation, scaledWidth, scaledHeight);
        context.imageSmoothingEnabled = false;
        context.drawImageScaledFromSource(temp, 0, 0, temp.width, temp.height, 0, 0, scaledWidth, scaledHeight);
      }
      else
      {
        canvas = new CanvasElement(width: temp.width, height: temp.height);
        CanvasRenderingContext2D context = canvas.context2D;
        _transformContextExifOrientation(canvas, _orientation, temp.width, temp.height);
        context.imageSmoothingEnabled = false;
        context.drawImage(temp, 0, 0);

      }

      /// make sure the image filesize <= maxByteSize
      int fileByteSize = maxByteSize + 1;
      double quality = 0.9;
      while (fileByteSize > maxByteSize && quality > 0.1)
      {
        _thumbnail.src = canvas.toDataUrl("image/jpeg", quality);
        quality -= 0.1;

        if (_thumbnail.src.contains("data:image/jpeg;base64,"))
        {
          List<int> bytes = CryptoUtils.base64StringToBytes(_thumbnail.src.substring("data:image/jpeg;base64,".length));
          _imageDataBase64 = CryptoUtils.bytesToBase64(bytes);
          fileByteSize = bytes.length;
        }
        else print("invalid src: ${_thumbnail.src}");
      }

      _isRaw = true;
      if (_onChange != null) _onChange();
    });
  }

  void _transformContextExifOrientation(CanvasElement canvas, int orientation, int width, int height)
  {
    CanvasRenderingContext2D context = canvas.context2D;

    canvas.width = width;
    canvas.height = height;
    context.setTransform(1, 0, 0, 1, 0, 0);

    switch (orientation)
    {
      case 1: /// no transform
        context.transform(1, 0, 0, 1, 0, 0);
        break;

      case 2:
        context.transform(-1, 0, 0, 1, width, 0);
        break;

      case 3:
        context.transform(-1, 0, 0, -1, width, height);
        break;

      case 4:
        context.transform(1, 0, 0, -1, 0, height);
        break;

      case 5: /// [5,6,7,8] has 90 degree rotation, flip canvas width/height
        canvas.width = height;
        canvas.height = width;
        context.transform(0, 1, 1, 0, 0, 0);
        break;

      case 6:
        canvas.width = height;
        canvas.height = width;
        context.transform(0, 1, -1, 0, height, 0);
        break;

      case 7:
        canvas.width = height;
        canvas.height = width;
        context.transform(0, -1, -1, 0, height, width);
        break;

      case 8:
        canvas.width = height;
        canvas.height = width;
        context.transform(0, -1, 1, 0, 0, width);
        break;

      default:
      break;
    }
  }

  set src(String value)
  {
    _thumbnail.src = value;
    if (_thumbnail.src.contains("data:image/jpeg;base64,"))
    {
      List<int> bytes = CryptoUtils.base64StringToBytes(_thumbnail.src.substring("data:image/jpeg;base64,".length));
      _imageDataBase64 = CryptoUtils.bytesToBase64(bytes);
    }
    else if (_thumbnail.src.contains("data:image/jpg;base64,"))
    {
      List<int> bytes = CryptoUtils.base64StringToBytes(_thumbnail.src.substring("data:image/jpg;base64,".length));
      _imageDataBase64 = CryptoUtils.bytesToBase64(bytes);
    }
  }

  String get imageDataBase64 => _imageDataBase64;
  bool get isRaw => _isRaw;

  void set onChange(onChangeImage callback)
  {
    _onChange = callback;
  }

  void set disabled(bool flag)
  {
    _file.disabled = flag;
  }

  void set label(String value)
  {
    if (_label != null) _label.setInnerHtml(value);
  }

  void _magnify(MouseEvent e)
  {
    e.stopPropagation();

    _popupContainer = new DivElement();
    _popupContainer.className = "upload_image_popup_container";
    _popupContainer.style.position = "fixed";
    _popupContainer.style.width = window.innerWidth.toString() + "px";
    _popupContainer.style.height = window.innerHeight.toString() + "px";
    _popupContainer.style.top = _popupContainer.style.left = "0";

    _popupContainer.onClick.first.then((_)
    {
      _popupContainer.remove();
      _popupContainer = null;
    });

    DivElement aligner = new DivElement();
    aligner.style.width = "100%";
    aligner.style.height = "100%";
    aligner.style.display = "flex";
    aligner.style.alignItems = "center";
    aligner.style.justifyContent = "center";

    ImageElement img = new ImageElement(src:_thumbnail.src);
    //img.style.maxWidth = "95%";
    img.style.maxHeight = "95%";

    aligner.append(img);
    _popupContainer.append(aligner);
    document.body.append(_popupContainer);
  }

  static const int maxByteSize = 102400;   /// bytes
  static const int maxDimension = 800;    /// pixels

  DivElement _root;
  DivElement _row;
  LabelElement _label;
  Element _magnifyIcon;

  onChangeImage _onChange;

  int _orientation = 0;

  String _imageDataBase64;
  FileReader _reader, _metaReader;
  FileUploadInputElement _file;
  ImageElement _thumbnail;
  DivElement _col;
  DivElement _popupContainer;
  bool _isRaw;
}

