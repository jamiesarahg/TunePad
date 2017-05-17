
// var tracking_min = document.createElement('script');
// tracking_min.src = '../tracking.js/build/tracking-min.js';
// var dat = document.createElement('script');
// dat.src = '../tracking.js/node_modules/dat.gui/build/dat.gui.min.js';
// var stats = document.createElement('script');
// stats.src = '../tracking.js/examples/assets/stats.min.js';
// var color_camera_gui = document.createElement('script');
// color_camera_gui.src = '../tracking.js/examples/assets/color_camera_gui.js';

// import * as tracking from 'tracking-min';
// import as dat from '../tracking.js/node_modules/dat.gui/build/dat.gui.min.js';
// import as stats from '../tracking.js/examples/assets/stats.min.js';
// import as color_camera_gui from '../tracking.js/examples/assets/color_camera_gui.js';

function onloade(){
  dartPrint_main('hey');
  var video = document.getElementById('video');
  var canvas = document.getElementById('canvas1');
  var context = canvas.getContext('2d');

  var tracker = new tracking.ColorTracker();

  tracking.track('#video', tracker, { camera: true });
    dartPrint_main('delete');

  tracker.on('track', function(event) {
    context.clearRect(0, 0, canvas.width, canvas.height);

    event.data.forEach(function(rect) {
      if (rect.color === 'custom') {
        rect.color = tracker.customColor;
      }

      context.strokeStyle = rect.color;
      context.strokeRect(rect.x, rect.y, rect.width, rect.height);
      context.font = '11px Helvetica';
      context.fillStyle = "#fff";
      context.fillText('x: ' + rect.x + 'px', rect.x + rect.width + 5, rect.y + 11);
      context.fillText('y: ' + rect.y + 'px', rect.x + rect.width + 5, rect.y + 22);
      dartPrint_main(String(rect.x)+','+String(rect.y)+','+String(rect.color));

    });
  });

 initGUIControllers(tracker);
};
