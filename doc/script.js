function setAttributes(node, config) {
  Object.keys(config).forEach(x => node.setAttribute(x, config[x]));
}

AFRAME.registerComponent('listenevents', {
  init: function() {
    const marker = this.el;
    const entity = this.el.children[0];

    marker.addEventListener('markerFound', function() {
      const now = (new Date()).getSeconds();
      setAttributes(entity.children[1], CONFIG[now % 4]);
    });
  }
});
