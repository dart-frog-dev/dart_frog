import { defineHastPlugin } from 'satteri';

export const normalizeHeadingIds = defineHastPlugin({
  name: 'normalize-heading-ids',
  element: {
    filter: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
    visit(node, ctx) {
      const id = node.properties.id;
      if (typeof id === 'string') {
        ctx.setProperty(node, 'id', id.replace(/^-+|-+$/g, ''));
      }
    },
  },
});