//= require InfiniteTreeFetch
//= require InfiniteTreeIds

class InfiniteTreeReorderActions {
  static EVENT_MOVE_START = 'infiniteTreeReorder:moveStart';
  static EVENT_MOVE_SUCCESS = 'infiniteTreeReorder:moveSuccess';
  static EVENT_MOVE_ERROR = 'infiniteTreeReorder:moveError';
  static EVENT_MOVE_SKIPPED = 'infiniteTreeReorder:moveSkipped';

  constructor() {
    this.componentEl = document.getElementById('infinite-tree-component');
    if (!this.componentEl) return;

    this.containerEl = this.componentEl.querySelector(
      '#infinite-tree-container'
    );
    if (!this.containerEl) return;

    this.rootUri = this.componentEl.getAttribute('data-root-uri') || '';
    this.fetch = new InfiniteTreeFetch(this.rootUri);
    this.inFlight = false;
    this.pendingHighlightUris = [];

    this.#bindEvents();
  }

  #bindEvents() {
    this.containerEl.addEventListener(
      InfiniteTreeDragDrop.EVENT_DROP_INTENT,
      this.#onDropIntent.bind(this)
    );

    this.containerEl.addEventListener(
      'infiniteTree:redisplayAndShowComplete',
      this.#onRedisplayAndShowComplete.bind(this)
    );
  }

  async #onDropIntent(event) {
    if (this.inFlight) return;

    const move = this.#moveFromIntent(event.detail || {});
    if (!move) {
      this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_SKIPPED, {
        reason: 'invalid',
      });
      return;
    }

    if (this.#isNoopMove(move)) {
      this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_SKIPPED, {
        reason: 'noop',
        move,
      });
      return;
    }

    this.inFlight = true;
    this.containerEl.classList.add('reorder-move-in-flight');
    this.containerEl.setAttribute('data-reorder-move-in-flight', 'true');
    this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_START, move);

    try {
      const response = await this.fetch.acceptChildren(
        move.targetParentUri,
        move.childUris,
        move.adjustedIndex
      );

      this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_SUCCESS, {
        ...move,
        response,
      });

      this.#redisplayMovedNode(move.childUris);
    } catch (error) {
      console.error('InfiniteTree reorder move failed:', error);
      this.#showMoveError();
      this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_ERROR, {
        ...move,
        error: String(error),
      });
      this.#dispatch('infiniteTree:error', {
        type: 'reorder_move_failed',
        message: String(error),
        context: move,
      });
      this.#clearInFlight();
    }
  }

  #moveFromIntent(detail) {
    const childUris = Array.isArray(detail.effectiveSourceUris)
      ? detail.effectiveSourceUris.filter(Boolean)
      : [];
    const sourceNodes = Array.isArray(detail.effectiveSourceNodes)
      ? detail.effectiveSourceNodes.filter(Boolean)
      : [];
    const targetParentUri = detail.targetParentUri || this.rootUri;
    const rawIndex = Number(detail.targetIndex);

    if (
      childUris.length === 0 ||
      !targetParentUri ||
      !Number.isFinite(rawIndex)
    ) {
      return null;
    }

    const sourcePositions = sourceNodes.map(node => ({
      node,
      uri: node.getAttribute('data-uri'),
      parentUri: this.#parentUriForNode(node),
      position: this.#positionForNode(node),
    }));
    const adjustedIndex = this.#adjustedIndex(
      targetParentUri,
      rawIndex,
      sourcePositions
    );

    return {
      childUris,
      sourceNodes,
      sourcePositions,
      targetNode: detail.targetNode || null,
      targetUri: detail.targetUri || null,
      targetParentUri,
      edge: detail.edge || null,
      rawIndex,
      adjustedIndex,
      sameParentMove: !!detail.sameParentMove,
    };
  }

  #adjustedIndex(targetParentUri, rawIndex, sourcePositions) {
    const adjustment = sourcePositions.filter(source => {
      return (
        source.parentUri === targetParentUri &&
        source.position !== null &&
        source.position < rawIndex
      );
    }).length;

    return Math.max(rawIndex - adjustment, 0);
  }

  #isNoopMove(move) {
    if (move.childUris.length !== 1 || move.sourcePositions.length !== 1) {
      return false;
    }

    const source = move.sourcePositions[0];
    if (source.parentUri !== move.targetParentUri || source.position === null) {
      return false;
    }

    return move.adjustedIndex === source.position;
  }

  #redisplayMovedNode(childUris) {
    const firstMovedUri = childUris[0];
    const targetHash = InfiniteTreeIds.treeLinkUrl(firstMovedUri);

    this.pendingHighlightUris = childUris.slice();

    this.containerEl.dispatchEvent(
      new CustomEvent('infiniteTreeRouter:replaceHash', {
        detail: { targetHash },
      })
    );

    this.containerEl.dispatchEvent(
      new CustomEvent('infiniteTreeRouter:redisplayAndShow', {
        detail: { targetHash },
      })
    );
  }

  #onRedisplayAndShowComplete() {
    if (this.pendingHighlightUris.length > 0) {
      this.#highlightMovedRows(this.pendingHighlightUris);
      this.pendingHighlightUris = [];
    }

    if (this.inFlight) {
      this.#clearInFlight();
    }
  }

  #highlightMovedRows(uris) {
    uris.forEach(uri => {
      const id = InfiniteTreeIds.uriToTreeId(uri);
      const node = this.containerEl.querySelector(`#${id}`);

      if (!node) return;

      node.classList.add('reparented-highlight');

      setTimeout(() => {
        node.classList.remove('reparented-highlight');
        node.classList.add('reparented');
      }, 500);
    });
  }

  #clearInFlight() {
    this.inFlight = false;
    this.containerEl.classList.remove('reorder-move-in-flight');
    this.containerEl.removeAttribute('data-reorder-move-in-flight');
  }

  #showMoveError() {
    if (!window.AS || typeof window.AS.openQuickModal !== 'function') return;

    window.AS.openQuickModal(
      'Unable to move records',
      'The records could not be moved. Please refresh the page and try again.'
    );
  }

  #positionForNode(node) {
    const positionAttr = node.getAttribute('data-tree-position');

    if (positionAttr !== null && positionAttr !== '') {
      const parsed = parseInt(positionAttr, 10);

      if (Number.isFinite(parsed)) return parsed;
    }

    const siblings = Array.from(
      node.parentElement.querySelectorAll(
        ':scope > li.node:not(.js-itree-synthetic-new)'
      )
    );
    const position = siblings.indexOf(node);

    return position === -1 ? null : position;
  }

  #parentUriForNode(node) {
    const parentLi = node.parentElement.closest('li.node');
    if (!parentLi) return this.rootUri;
    return parentLi.getAttribute('data-uri') || this.rootUri;
  }

  #dispatch(type, detail) {
    this.containerEl.dispatchEvent(
      new CustomEvent(type, {
        bubbles: true,
        detail,
      })
    );
  }
}
