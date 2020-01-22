function setAttributes(node, config) {
  Object.keys(config).forEach(x => node.setAttribute(x, config[x]));
}

function getCurrrentTime() {
  const date = new Date();
  return `${date.getHours()}:${date.getMinutes()}`;
}

AFRAME.registerComponent('listenevents', {
  init: function() {
    const marker = this.el;
    const entity = this.el.children[0];

    marker.addEventListener('markerFound', function() {
      const now = getCurrrentTime();
      const time = Object.keys(CONFIG[marker.id]).reverse().find(k => now > k);
      const conf = CONFIG[marker.id][time];
      setAttributes(entity.children[0], conf.text);
      setAttributes(entity.children[1], conf.cursor);
    });

    marker.addEventListener('markerLost', function() {
      // ???
    });
  }
});
