var trackerTask;
var tracker;

function onloade(){
  var tangible = document.getElementById('tangible').value;
  if (tangible == "true"){
    var video = document.getElementById('video');
    this.tracker = new tracking.ColorTracker();
    this.trackerTask = tracking.track('#video', this.tracker, { camera: true });
    trackerStart(this.tracker);
    initGUIControllers(this.tracker);
  } 
};

function trackerStart(){
    var canvas = document.getElementById('canvas1');
    var context = canvas.getContext('2d');
    this.tracker.on('track', function(event) {
      context.clearRect(0, 0, canvas.width, canvas.height);
      parseTrackingPucks_JS('delete');


      event.data.forEach(function(rect) {
        var x = rect.x+(rect.width/2);
        var y = rect.y+(rect.height/2);
        var rad = (rect.height * rect.width)/40;
        if (rad > 30){
          rad = 30;
        }
        parseTrackingPucks_JS(String(x)+','+String(y)+','+String(rect.color) + ','+  String(rad));
    });
  });
}

function trackerOff(){
  this.trackerTask.stop();
}

function trackerOn(){
  this.trackerTask.run();
}
