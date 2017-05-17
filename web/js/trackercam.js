var trackerTask;

function onloade(){
  var video = document.getElementById('video');

  var tracker = new tracking.ColorTracker();
  console.log('onload');
  console.log(this.trackerTask);
  this.trackerTask = tracking.track('#video', tracker, { camera: true });
  console.log('afteronload')
  console.log(this.trackerTask);

  trackerOn(tracker);
  //trackerTask.stop();

 initGUIControllers(tracker);
};

function trackerOn(tracker){
    var canvas = document.getElementById('canvas1');
    var context = canvas.getContext('2d');
    tracker.on('track', function(event) {
      context.clearRect(0, 0, canvas.width, canvas.height);
          dartPrint_main('delete');


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
}

function trackerOff(){
  console.log('this.trackerOff')
  console.log(this.trackerTask);
  trackerTask.stop();
}

function hello(){
  console.log('hello');
}