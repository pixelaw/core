use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};
use pixelaw::core::{
    utils::{Bounds, min, max, Position, MAX_DIMENSION},
    models::{
        pixel::{Pixel},
        {
            area::{
                RTreeNode, RTree, Area, RTreeTraitImpl, RTreeNodePackableImpl, ChildrenPackableImpl,
                BoundsTraitImpl, ROOT_RTREENODE, ROOT_ID
            }
        }
    }
};
use super::RTreeTrait;
use super::super::models::area::BoundsTrait;


pub fn find_node_for_position(
    world: IWorldDispatcher, position: Position, node_id: u64, has_area: bool
) -> u64 {
    let node: RTreeNode = node_id.unpack();

    let found = node.bounds.contains_position(position);

    if found && node.is_area == has_area {
        // This is the area node we were looking for
        return node_id;
    } else if !found {
        // We're not going to be finding anything here
        return 0;
    }

    // Let's continue looking at children, something maybe below

    // Load the treenode from storage so we can inspect children
    let treenode: RTree = get!(world, (node_id), RTree);

    let children: Span<u64> = treenode.get_children();
    let mut found_child_id: u64 = 0;

    for child_id in children {
        let id = find_node_for_position(world, position, *child_id, has_area);
        if id != 0 {
            found_child_id = id;
            break;
        }
    };

    found_child_id
}


pub fn get_ancestors(world: IWorldDispatcher, ref ancestors: Array<u64>, search_node_id: u64) {
    if ancestors.len() == 0 {
        ancestors.append(ROOT_ID);
    }

    let current_id = ancestors[ancestors.len() - 1];
    let current_node: RTree = get!(world, (*current_id), RTree);
    let children: Span<u64> = current_node.get_children();

    for child_id in children {
        if *child_id == search_node_id {
            ancestors.append(*child_id);
            break;
        }
        let child: RTreeNode = (*child_id).unpack();
        let search_node: RTreeNode = search_node_id.unpack();
        if child.bounds.contains_bounds(search_node.bounds) {
            // found it
            ancestors.append(*child_id);

            get_ancestors(world, ref ancestors, search_node_id);
            break;
        }
    };
}

pub fn print_tree(world: IWorldDispatcher, node_id: u64, indent: ByteArray) {
    let node: RTreeNode = node_id.unpack();
    let treenode: RTree = get!(world, (node_id), RTree);

    let children: Span<u64> = treenode.get_children();

    println!("{} Node: {} {:?}, children {:?}", indent, node_id, node, children);

    let mut new_indent: ByteArray = "    " + indent.clone();

    for child_id in children {
        print_tree(world, *child_id, new_indent.clone());
    };
}


// Calculates bounds that span all given nodes
fn spanning_bounds(nodes: Span<u64>) -> Bounds {
    let mut result = Bounds { x_min: MAX_DIMENSION, y_min: MAX_DIMENSION, x_max: 0, y_max: 0 };

    for node in nodes {
        let n: RTreeNode = node.deref().unpack();
        let b = n.bounds;
        if b.x_min < result.x_min {
            result.x_min = b.x_min;
        }
        if b.x_max > result.x_max {
            result.x_max = b.x_max;
        }
        if b.y_min < result.y_min {
            result.y_min = b.y_min;
        }
        if b.y_max > result.y_max {
            result.y_max = b.y_max;
        }
    };

    result
}

fn distribute_children(children: Span<u64>) -> (Span<u64>, Span<u64>) {
    // Don't split if only 1 child
    assert_gt!(children.len(), 1);

    // Find the optimal way to split the childen into 2 smallest groups

    let mut max_difference = 0;
    let mut seed_child_1 = 0;
    let mut seed_child_2 = 1;

    let mut i = 0;
    let mut j = 1;

    // Precache a collection of the unpacked children ids
    let mut bounds: Array<Bounds> = array![];
    for child in children {
        let tn: RTreeNode = (*child).unpack();
        bounds.append(tn.bounds);
    };

    while i < children.len() {
        while j < children.len() {
            let bounds_i = bounds.at(i).deref();
            let bounds_j = bounds.at(j).deref();

            let combined_area = bounds_i.combine(bounds_j).area();

            let difference = combined_area
                - bounds.at(i).deref().area()
                + bounds.at(j).deref().area();

            if (difference > max_difference) {
                max_difference = difference;
                seed_child_1 = i;
                seed_child_2 = j;
            }

            j += 1;
        };
        i += 1;
    };

    // These two are the "worst" combination, so can be seed for the split
    let mut arr1 = array![*children[seed_child_1]];
    let mut arr2 = array![*children[seed_child_2]];

    let mut i = 0;

    // Get the bounds for both seeds for easier comparison later
    let bounds1 = *bounds[seed_child_1];
    let bounds2 = *bounds[seed_child_2];

    while i < bounds.len() {
        // Only process the remaining children
        if i != seed_child_1 && i != seed_child_2 {
            let compared: Bounds = *bounds[i];

            let enlargement1 = bounds1.combine(compared).area();
            let enlargement2 = bounds2.combine(compared).area();

            if enlargement1 < enlargement2 {
                // This item goes with seed1
                arr1.append(*children[i]);
            } else {
                // This item goes with seed2
                arr2.append(*children[i]);
            }
        }

        i += 1;
    };

    (arr1.span(), arr2.span())
}

// Splits the current node, and those above it if needed
pub fn update_ancestry(
    world: IWorldDispatcher, ancestry: Span<u64>, level: usize, updated_children: Array<u64>
) -> u64 {
    // Step 1: Identify Node to update
    let mut current_node_id = *ancestry[level];

    let current_treenode: RTree = get!(world, (current_node_id), RTree);
    let mut current_node: RTreeNode = current_treenode.get_node();

    // // Step 3: Remove the old node from storage, we're replacing it with 2 new ones
    delete!(world, (current_treenode));

    if updated_children.len() <= 4 {
        // Get children of parent, if not root
        if level != 0 {
            let current_spanningbounds = spanning_bounds(updated_children.span());
            current_node.bounds = current_spanningbounds;
            let updated_node_id = current_node.pack();
            set!(world, RTree { id: updated_node_id, children: updated_children.span().pack() });

            let parent_node_id = *ancestry[level - 1];
            let parent_treenode: RTree = get!(world, (parent_node_id), RTree);
            let parent_updated_children = parent_treenode
                .replace_child_id(current_node_id, updated_node_id);
            update_ancestry(world, ancestry, level - 1, parent_updated_children);

            current_node_id = updated_node_id;
        } else {
            // This is root, and the ID has to stay the same (bounds will never change)
            set!(world, RTree { id: current_node_id, children: updated_children.span().pack() });
        }

        return current_node_id;
    }

    // Step 4: distribute the new children over two collections
    let (current_children, sibling_children) = distribute_children(updated_children.span());

    // Step 5: Calculate New Bounds
    let current_spanningbounds = spanning_bounds(current_children);
    let sibling_spanningbounds = spanning_bounds(sibling_children);

    // Step 6: Create New Nodes
    current_node.bounds = current_spanningbounds;
    let updated_node_id = current_node.pack();
    let sibling_node = RTreeNode {
        bounds: sibling_spanningbounds, is_leaf: current_node.is_leaf, is_area: false
    };
    let sibling_node_id = sibling_node.pack();

    // Add the two new ones
    set!(world, RTree { id: updated_node_id, children: current_children.pack() });
    set!(world, RTree { id: sibling_node_id, children: sibling_children.pack() });

    if level == 0 {
        // Move the node and sibling as new children under ROOT

        let updated_root_children = array![updated_node_id, sibling_node_id].span();

        set!(world, RTree { id: ROOT_ID, children: updated_root_children.pack() });

        return current_node_id;
    }

    // Remove the old node
    delete!(world, (current_treenode));

    // Step 7: Update the parent children
    let parent_node_id = *ancestry[level - 1];
    let parent_treenode: RTree = get!(world, (parent_node_id), RTree);

    // Replace the current node
    let mut parent_updated_children = parent_treenode
        .replace_child_id(current_node_id, updated_node_id);

    // Add the new sibling
    parent_updated_children.append(sibling_node_id);

    // Update the parents
    update_ancestry(world, ancestry, level - 1, parent_updated_children);

    updated_node_id
}

pub fn choose_leaf(
    world: IWorldDispatcher, node_id: u64, new_bounds: Bounds, parent_id: u64
) -> RTree {
    let node: RTreeNode = node_id.unpack();

    // Load the parent from storage
    let treenode: RTree = get!(world, (node_id), RTree);

    // The parent is a leaf and can be used
    if node.is_leaf {
        return treenode;
    }

    // Find the most suitable child (that fits the new area without expanding the least)
    let best_child_id = choose_best_child(node, treenode.get_children(), new_bounds);

    // Recursively keep looking for the best child, until the leaf with the smallest new area is
    // found
    choose_leaf(world, best_child_id, new_bounds, parent_id)
}


fn choose_best_child(parent: RTreeNode, children: Span<u64>, new: Bounds) -> u64 {
    let mut best_child_id: u64 = 0;
    let mut best_child_area: u32 = 0;

    let mut best_new_area: u32 = 0x40000000; //  pow2_32_max (15bit*15bit)

    for child_id in children {
        let child: RTreeNode = (*child_id).unpack();
        let new_area = child.bounds.combine(new).area();

        if new_area < best_new_area {
            best_new_area = new_area;
            best_child_area = child.bounds.area();
            best_child_id = *child_id;
        } else if new_area == best_new_area && child.bounds.area() < best_child_area {
            best_child_id = *child_id;
        }
    };

    (best_child_id)
}

pub fn check_area_containing(world: IWorldDispatcher, bounds: Bounds, node_id: u64) {
    let node: RTreeNode = node_id.unpack();

    let treenode: RTree = get!(world, (node_id), RTree);

    let children: Span<u64> = treenode.get_children();

    // Evaluate children
    for child_id in children {
        let child: RTreeNode = (*child_id).unpack();
        if node.is_leaf {
            // We're looping Area's now
            assert(!bounds.contains_bounds(child.bounds), 'overlap containing');
        } else {
            // We're looping Nodes now, so recurse only if the node contains our bounds
            if child.bounds.contains_bounds(bounds) {
                check_area_containing(world, bounds, *child_id);
            }
        }
    };
}

// TODO testing
pub fn find_node_spanning_bounds(
    world: IWorldDispatcher, bounds: Bounds, node_id: u64, is_area: bool
) -> u64 {
    let node: RTreeNode = node_id.unpack();
    let mut result: u64 = ROOT_ID;

    // If the given node doesnt contain it, just return immediately
    if !node.bounds.contains_bounds(bounds) || is_area && node.is_leaf {
        return ROOT_ID;
    }

    let treenode: RTree = get!(world, (node_id), RTree);

    let children: Span<u64> = treenode.get_children();

    // Evaluate children
    for child_id in children {
        let child: RTreeNode = (*child_id).unpack();

        // Check the children
        if child.bounds.contains_bounds(bounds) {
            result = find_node_spanning_bounds(world, bounds, *child_id, is_area);

            break;
        }
    };
    result
}


pub fn check_area_overlap(world: IWorldDispatcher, bounds: Bounds) {
    // We can optimize the start of the search by caching the node that contains the new bounds
    // and using that instead of ROOT_ID
    let node_search_id = find_node_spanning_bounds(world, bounds, ROOT_ID, false);

    // Check if our new bounds contain an existing area
    check_area_containing(world, bounds, node_search_id);

    // Check that each of the 4 corners are not inside of an existing area
    assert(
        find_node_for_position(
            world, Position { x: bounds.x_min, y: bounds.y_min }, node_search_id, true
        ) == 0,
        'overlap topleft'
    );
    assert(
        find_node_for_position(
            world, Position { x: bounds.x_max, y: bounds.y_min }, node_search_id, true
        ) == 0,
        'overlap topright'
    );
    assert(
        find_node_for_position(
            world, Position { x: bounds.x_min, y: bounds.y_max }, node_search_id, true
        ) == 0,
        'overlap bottomleft'
    );
    assert(
        find_node_for_position(
            world, Position { x: bounds.x_max, y: bounds.y_max }, node_search_id, true
        ) == 0,
        'overlap bottomright'
    );
}

pub fn add_area_node(world: IWorldDispatcher, bounds: Bounds) -> u64 {
    // Check that the bounds are correct (min < max etc)
    bounds.check();

    // Ensure the new area is not overlapping (entirely or partially) with an existing
    check_area_overlap(world, bounds);

    // Step 1: Prepare the Leaf (parent, leaf)
    let mut leaf: RTree = choose_leaf(world, ROOT_ID, bounds, ROOT_ID);

    // Step 2: Create New Area Node
    let new_area = RTreeNode { bounds, is_leaf: false, is_area: true };
    let new_area_id = new_area.pack();

    // Step 3: Update Parent Node, Add the area node to the parent children array
    let updated_leaf_children: Array<u64> = leaf.add_child_id(new_area_id);

    // Step 4: Handle recursive ancestor resizing
    let mut ancestors: Array<u64> = array![];
    get_ancestors(world, ref ancestors, leaf.id);

    update_ancestry(
        world,
        ancestors.span(), // ancestors
        ancestors.len() - 1, // level 
        updated_leaf_children // new id (new leaf_id can be calculated from this)
    );

    // Step 6: Return New Area ID
    new_area_id
}

pub fn remove_area(world: IWorldDispatcher, area_id: u64) { // TODO implement
}

