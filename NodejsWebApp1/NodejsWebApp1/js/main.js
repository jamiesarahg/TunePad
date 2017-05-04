// Your code here!

$(document).ready(function () {
    var my_canvas = document.getElementById('canvas');
    var context = my_canvas.getContext("2d");

    $('#black').click(function () {
        context.fillStyle = "#99";
        context.beginPath();
        context.arc(100, 100, 10, 0, 2 * Math.PI);
        context.fill();
    });
});