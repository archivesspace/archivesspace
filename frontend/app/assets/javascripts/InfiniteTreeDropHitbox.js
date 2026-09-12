/**
 * Derived from Atlassian Pragmatic Drag and Drop (Apache-2.0):
 * packages/hitbox/src/tree-item.ts (standardHitbox).
 */
class InfiniteTreeDropHitbox {
  /**
   * @param {{x:number, y:number}} client
   * @param {{top:number, bottom:number, height:number}} borderBox
   * @returns {'top'|'into'|'bottom'}
   */
  static standardHitbox(client, borderBox) {
    const quarter = borderBox.height / 4;
    if (client.y <= borderBox.top + quarter) return 'top';
    if (client.y >= borderBox.bottom - quarter) return 'bottom';
    return 'into';
  }
}

window.InfiniteTreeDropHitbox = InfiniteTreeDropHitbox;
