// Copyright (c) 2016, Patrick Minogue. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.


import 'dart:async';
import 'dart:html';
import 'dart:math';

final double HALF_PI = 0.5 * pi;
final double DOUBLE_PI = 2 * pi;

// An analog stopwatch
// param int duration: timeout duration in milliseconds, must be dividable by 4
// param DivElement container: Html container which will hold the stopwatch
class StopwatchElement
{
  StopwatchElement(this._duration, this._container, { Duration delay, Function onDone : null, bool ccw : false })
  {
    if (_duration == null) throw new ArgumentError.notNull("duration");
    if (_container == null) throw new ArgumentError.notNull("container");
    if (_duration <= 0) throw new ArgumentError("Duration must be > 0 seconds)");

    _ccw = ccw;
    _currentSeconds = 0.0;
    _stopped = (delay != null);
    _callback = onDone;
    _quarterDurationSeconds = _duration.toDouble()/4000;
    _firstFrame = true;
    _radiansPerMillisecond = DOUBLE_PI / _duration;
    String widthStr = _container.getComputedStyle().width;
    _dimension = int.parse(widthStr.substring(0, widthStr.indexOf("px")));
    _halfDimension = 0.5 * _dimension;
    _margin = _dimension / 7;

    _container.style.position = "relative";
    _container.style.margin = (0.5*_margin).toString() + "px";
    _q0 = new SpanElement();
    _q1 = new SpanElement();
    _q2 = new SpanElement();
    _q3 = new SpanElement();
    _q0.style.color = _q1.style.color = _q2.style.color = _q3.style.color = "#000";
    /*_q0.style.fontWeight = _q1.style.fontWeight = _q2.style.fontWeight = _q3.style.fontWeight = "bold";*/
    _q0.style.fontSize = _q1.style.fontSize = _q2.style.fontSize = _q3.style.fontSize = "14px";
    _q0.style.position = _q1.style.position = _q2.style.position = _q3.style.position = "absolute";
    _q0.style.bottom = _q2.style.top = (_dimension - 0.5*_margin).toString() + "px";
    _q0.style.left = _q2.style.left = "0";
    _q0.style.textAlign = _q2.style.textAlign = "center";
    _q0.style.width = _q2.style.width = "100%";
    _q1.style.left = _q3.style.right = (_dimension - 0.5*_margin).toString() + "px";
    _q1.style.top = _q3.style.top = (_halfDimension - 7).toString() + "px";

    _q0.innerHtml = "0'";
    _q1.innerHtml = _quarterDurationSeconds.toInt().toString() + "'";
    _q2.innerHtml = (2*_quarterDurationSeconds).toInt().toString() + "'";
    _q3.innerHtml = (3*_quarterDurationSeconds).toInt().toString() + "'";

    _canvas = new CanvasElement(width:_dimension, height:_dimension);
    _context = _canvas.getContext("2d");
    _context.lineWidth = 1;
    _container.children.add(_canvas);
    _container.children.add(_q0);
    _container.children.add(_q1);
    _container.children.add(_q2);
    _container.children.add(_q3);
    _currentRadians = -DOUBLE_PI;

    if (delay != null)
    {
      /// draw the initial clock in case there's a delay
      _context.clearRect(0, 0, _dimension, _dimension);
      _context.setFillColorRgb(0, 173, 217);
      _context.setStrokeColorRgb(0, 203, 247);
      _context.beginPath();
      _context.arc(_halfDimension, _halfDimension, _halfDimension - _margin, 0, DOUBLE_PI);
      _context.fill();
      _context.stroke();
      _delay = new Timer(delay, ()
      {
        _stopped = false;
        _render(null);
      });
    }
    else _render(null);
  }

  void stop([bool cancel_callback = false])
  {
    if (_delay != null) _delay.cancel();
    _stopped = true;
    if (cancel_callback = true) _callback = null;
  }

  void _render(num dt)
  {
    if (dt != null)
    {
      if (_firstFrame == true)
      {
        _animationStartTime = dt;
        _firstFrame = false;
      }
      _currentSeconds = dt - _animationStartTime;

      if (_ccw) _currentRadians = -HALF_PI - (dt - _animationStartTime) * _radiansPerMillisecond;
      else _currentRadians = -HALF_PI + (dt - _animationStartTime) * _radiansPerMillisecond;
      _context.clearRect(0, 0, _dimension, _dimension);
      _context.setFillColorRgb(0, 173, 217);
      _context.setStrokeColorRgb(0, 203, 247);

      _context.beginPath();
      _context.arc(_halfDimension, _halfDimension, _halfDimension - _margin, 0, DOUBLE_PI);
      _context.fill();
      _context.stroke();
      _context.beginPath();
      _context.moveTo(_halfDimension, _halfDimension);
      _context.setFillColorRgb(255, 255, 255);
      _context.arc(_halfDimension, _halfDimension, _halfDimension - _margin - 0.5*_context.lineWidth, -HALF_PI, _currentRadians);
      _context.fill();
      _context.stroke();
    }

    if (_currentSeconds < _duration && !_stopped) window.requestAnimationFrame(_render);
    else if (_callback != null) _callback();
  }

  bool _stopped;
  bool _firstFrame;
  int _dimension, _duration;
  double _quarterDurationSeconds;
  var _context;
  double _radiansPerMillisecond, _currentRadians, _halfDimension, _margin, _animationStartTime, _currentSeconds;
  DivElement _container;
  SpanElement _q0, _q1, _q2, _q3;
  CanvasElement _canvas;
  Function _callback;
  Timer _delay;
  bool _ccw;
}