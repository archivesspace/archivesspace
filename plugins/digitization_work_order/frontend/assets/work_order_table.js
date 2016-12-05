(function(exports) {

    var TABLE_SETTINGS = {
        row_height: 50,
        header_height: 40,
        column_widths: [100, 4500],
        bottom_padding_px: 50,
    };

    var flattenTree = function (tree, level) {
        if (level === undefined) {
            level = 0;
        }

        var root = $.extend({}, tree);
        root['level'] = level;
        root['selected'] = false;
        delete root['children'];

        var result = [root]

        if (tree['children'] && tree['children'].length > 0) {
            root['children'] = true
            for (var i = 0; i < tree['children'].length; i++) {
                result = result.concat(flattenTree(tree['children'][i], level + 1));
            }
        }

        return result;
    };

    var getIndexForUri = function(tree, uri) {
        var index;

        $.each(tree, function(i, record) {
            if (record.uri == uri) {
                index = i;
                return false
            }
        });

        if (index == null) {
            throw "uri not found in tree: " + uri;
        }

        return index;
    }


    var filterTree = function (tree) {
        /* A stack of the ancestry of the current element.  For example, a
           record four levels of nesting deep will have an ancestry of [0, 1, 2,
           3], since its parent was three levels deep, its grandparent was two
           levels, and so on. */
        var ancestorLevels = [];

        return tree.filter(function (elt) {
            /* Wind back our list of ancestors to find the parent of the
               current record.  If we go from level 5 to level 2, we've moved
               back up the tree a couple of steps and need to discard those
               entries. */
            while (ancestorLevels[ancestorLevels.length - 1] >= elt.level) {
                ancestorLevels.pop();
            }

            /* If the current record is selected, or if its parent was, we keep it.
               Additionally, the root node is always kept. */
            var keepRecord = (elt['level'] == 0 ||
                              elt['selected'] ||
                              (elt['level'] - 1) === ancestorLevels[ancestorLevels.length - 1]);

            /* If the current record met the criteria, record it so its children
               are also kept. */
            if (elt['level'] == 0 || elt['selected']) {
                ancestorLevels.push(elt['level'])
            }

            return keepRecord;
        });
    };


    var renderTable = function (tree) {

        var parents_selected = [tree[0]['selected']];

        // We only want to keep nodes that are either: the root node, selected, the immediate child of a selected node
        var filtered_tree = filterTree(tree);

        var selected_count = filtered_tree.filter(function (elt) { return elt['selected']; }).length;

        $("#selectedCount").html(selected_count);
        $("#selectedCountInModal").html(selected_count);
        $(".submit-btn").prop("disabled", selected_count === 0);

        $("#work_order_table").empty();

        var tableData = new fattable.SyncTableModel();
        tableData.getCellSync = function(i,j) {
            if (i >= filtered_tree.length) {
                /* Past the end of the table, so we render a blank */
                return {
                    'content': '',
                    'rowId': i,
                };
            }

            if (j === 0) {
                /* First column: render a checkbox */
                return {
                    "content": "<label class='work-order-checkbox-label'><input data-rowid='"+ i +"' id='item"+i+"' value='"+filtered_tree[i]['uri']+"' type='checkbox' " + (filtered_tree[i]['selected'] ? "checked" : "") + " /></label>",
                    "rowId": i,
                }
            }

            /* Left-pad each item relative to its level */
            var spaces = '<div class="work-order-spaces">';

            for (var space = 0; space < filtered_tree[i]['level']; space++) {
                spaces += '<span class="work-order-space"></span>';
            }

            spaces += '</div>';

            var metadata = '';

            var fields = [
                {property: 'ref_id', label: 'Ref ID'},
                {property: 'component_id', label: 'Component ID'},
                {property: 'identifier', label: 'Collection Identifier'},
                {property: 'container', label: 'Container'}
            ];

            $.each(fields, function (idx, elt) {
                if (filtered_tree[i][elt.property]) {
                    var fragment = $('<div><span class="metadata-field-label"></span><span class="metadata-field-value"></span></div>');
                    $(fragment).find('.metadata-field-label').text(elt.label);
                    $(fragment).find('.metadata-field-value').text(filtered_tree[i][elt.property]);
                    metadata += $(fragment).html();
                }
            });

            var content = (spaces +
                           '<div class="work-order-entry">' +
                           '<div><label class="work-order-label" for="item'+i+'">' + filtered_tree[i]['title'] + '</label></div>' +
                           '<div>' + metadata + '</div>' +
                           '</div>');

            if (filtered_tree[i]['children']) {
                content = '<span class="work-order-has-children">' + content + '</span>';
            }

            return {
                "content": content,
                "rowId": i
            }
        };

        tableData.getHeaderSync = function(j) {
            if (j == 0) {
                return "Selected";
            } else if (j == 1) {
                return "Record Title";
            } else {
                return "Col" + j;
            }
        }

        var painter = new fattable.Painter();
        painter.fillCell = function(cellDiv, data) {
            cellDiv.innerHTML = data.content;
            if (data.rowId % 2 == 0) {
                cellDiv.className = "even";
            }
            else {
                cellDiv.className = "odd";
            }
        }

        painter.fillCellPending = function(cellDiv, data) {
            cellDiv.textContent = "";
            cellDiv.className = "pending";
        }

        var table = fattable({
            "container": "#work_order_table",
            "model": tableData,
            "nbRows": filtered_tree.length,
            "rowHeight": TABLE_SETTINGS.row_height,
            "headerHeight": TABLE_SETTINGS.header_height,
            "painter": painter,
            "columnWidths":  TABLE_SETTINGS.column_widths
        });

        var idealHeight = $(window).height() - $('#work_order_buttons').height() - TABLE_SETTINGS.bottom_padding_px;
        $("#work_order_table").height(idealHeight);

        window.onresize = function() {
            table.setup();
        }

        return table;
    }

    exports.initWorkOrderTable = function (tree) {
        var flattened = flattenTree(tree);

        workOrderFatTable = renderTable(flattened);

        $("#work_order_table").on("click", ":input", function(event) {
            var $checkbox = $(event.target);

            var rowid = parseInt($checkbox.data("rowid"));
            var uri = $checkbox.val();

            // update record 'selected' state
            var index = getIndexForUri(flattened, uri);
            flattened[index].selected = $checkbox.is(":checked");

            // update all children
            var level = flattened[index].level;
            for (var i = index + 1; i < flattened.length; i++) {
                if (flattened[i].level > level) {
                    flattened[i].selected = $checkbox.is(":checked");
                } else {
                    break;
                }
            }

            var offsetTop = workOrderFatTable.scroll.scrollTop;

            workOrderFatTable = renderTable(flattened);

            // navigate back to the row you just clicked
            workOrderFatTable.goTo(rowid, 0);
            workOrderFatTable.scroll.setScrollXY(0, offsetTop);
        });


        $("#cancelWorkOrder").on("click", function(event) {
	    event.preventDefault();
	    $(".modal_overlay").hide();
	    $(".work_order_modal").hide();
	});

        $(".submit-btn").on("click", function() {
            var self = $(this);

	    if (self.attr('id') == 'showWorkOrderModal') {
		$(".modal_overlay").show();
		$(".work_order_modal").show();
		return;
	    }

	    if (self.attr('id') == 'downloadWorkOrder') {
		$(".modal_overlay").hide();
		$(".work_order_modal").hide();
	    }

            var extras = [];

            $('.additional-options input[type="checkbox"]').each(function (idx, checkbox) {
		    if ($(checkbox).is(':checked')) {
			extras.push($(checkbox).prop('name'));
			    }
            });

            var selected = [];
            $.each(flattened, function(i, elt) {
                if (elt['selected']) {
                    selected.push(elt['uri']);
                }
            });

	    var form = $("#work_order_form");
	    var form_fields = form.find(".report-fields").empty();

	    $(form_fields).append(
			   $("<input>")
			   .attr("type", "hidden")
			   .attr("name", "selected")
			   .val(JSON.stringify(selected))
			   );

	    $(form_fields).append(
			   $("<input>")
			   .attr("type", "hidden")
			   .attr("name", "report_type")
			   .val(self.prop('id'))
			   );

	    $(form_fields).append(
			   $("<input>")
			   .attr("type", "hidden")
			   .attr("name", "extras")
			   .val(JSON.stringify(extras))
			   );

	    $(form).submit();

        });
    };
})(window);
