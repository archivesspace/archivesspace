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
    this.rootParts = InfiniteTreeIds.rootUriToParts(this.rootUri);
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
      'infiniteTree:redisplayAndReopenComplete',
      this.#onRedisplayAndReopenComplete.bind(this)
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
      const recovery = this.#recoveryStateForMove(move);
      const response = await this.fetch.acceptChildren(
        move.targetParentUri,
        move.childUris,
        move.adjustedIndex
      );

      this.#dispatch(InfiniteTreeReorderActions.EVENT_MOVE_SUCCESS, {
        ...move,
        response,
      });

      this.#redisplayAndReopen(recovery);
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

  #recoveryStateForMove(move) {
    const selectedUri = this.#selectedUri();
    const sourceParentUris = move.sourcePositions
      .map(source => source.parentUri)
      .filter(Boolean);
    const expandedParentUris = Array.from(
      this.containerEl.querySelectorAll(
        'li.node[aria-expanded="true"]:not(.js-itree-synthetic-new)'
      )
    )
      .map(node => node.getAttribute('data-uri'))
      .filter(Boolean);
    const reopenUris = this.#uniqueUris([
      move.targetParentUri,
      ...sourceParentUris,
      ...expandedParentUris,
    ]);

    return {
      reopenUris,
      selectedUri,
      revealUri: move.childUris[0],
      highlightUris: move.childUris.slice(),
      scrollTop: this.containerEl.scrollTop,
      revealStrategy: 'restore-scroll-then-reveal-if-needed',
    };
  }

  #redisplayAndReopen(recovery) {
    if (!recovery.revealUri) {
      this.#clearInFlight();
      return;
    }

    const selectedHash = InfiniteTreeIds.treeLinkUrl(
      recovery.selectedUri || this.rootUri
    );
    this.pendingHighlightUris = recovery.highlightUris.slice();

    this.containerEl.dispatchEvent(
      new CustomEvent('infiniteTreeRouter:replaceHash', {
        detail: { targetHash: selectedHash },
      })
    );

    this.containerEl.dispatchEvent(
      new CustomEvent('infiniteTreeRouter:redisplayAndReopen', {
        detail: recovery,
      })
    );
  }

  #onRedisplayAndReopenComplete(event) {
    const succeeded = event.detail ? event.detail.succeeded !== false : true;

    if (this.pendingHighlightUris.length > 0) {
      if (succeeded) this.#highlightMovedRows(this.pendingHighlightUris);
      this.pendingHighlightUris = [];
    }

    if (this.inFlight) {
      this.#clearInFlight();
    }
  }

  #selectedUri() {
    const selectedNode = this.containerEl.querySelector('li.node.selected');

    if (selectedNode) {
      return selectedNode.getAttribute('data-uri') || this.rootUri;
    }

    return this.#uriFromHash(window.location.hash) || this.rootUri;
  }

  #uriFromHash(hash) {
    if (!hash || !this.rootParts) return null;

    const treeId = InfiniteTreeIds.locationHashToHtmlId(hash);
    const parts = InfiniteTreeIds.parseTreeId(treeId);

    if (!parts) return null;
    if (parts.type === this.rootParts.type && parts.id === this.rootParts.id) {
      return this.rootUri;
    }

    return `/repositories/${this.rootParts.repoId}/${parts.type}s/${parts.id}`;
  }

  #uniqueUris(uris) {
    return Array.from(new Set(uris.filter(Boolean)));
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
