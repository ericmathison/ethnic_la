/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import HeatmapJS from 'heatmap.js'

window.onload = function() {
    let h = HeatmapJS.create({
      container: document.querySelector('.heatmap_area')
    });

    h.setData({
      max: 10,
      min: 0,
      data: [{ x: 10, y: 15, value: 5}, { x: 370, y: 70, value: 4}, { x: 330, y: 70, value: 2}, { x: 130, y: 70, value: 9}]
    });
}
