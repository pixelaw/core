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


fn combinedArea(parent: Bounds, new: Bounds) -> u32 {
    // TODO use the bounds.combine()
    let x_min = min(parent.x_min, new.x_min);
    let y_min = min(parent.y_min, new.y_min);
    let x_max = max(parent.x_max, new.x_max);
    let y_max = max(parent.y_max, new.y_max);

    (x_max - x_min).into() * (y_max - y_min).into()
}


fn choose_best_child(parent: RTreeNode, children: Span<u64>, new: Bounds) -> u64 {
    let mut best_child_id: u64 = 0;
    let mut best_child_area: u32 = 0;

    let mut best_new_area: u32 = 0x40000000; //  pow2_32_max (15bit*15bit)

    for child_id in children {
        let child: RTreeNode = (*child_id).unpack();
        let new_area = combinedArea(child.bounds, new);

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

pub fn choose_leaf(
    world: IWorldDispatcher, node_id: u64, new_bounds: Bounds, parent_id: u64
) -> (RTree, u64) {
    let node: RTreeNode = node_id.unpack();

    // Load the parent from storage
    let treenode: RTree = get!(world, (node_id), RTree);

    // The parent is a leaf and can be used
    if node.is_leaf {
        return (treenode, parent_id);
    }

    // Find the most suitable child (that fits the new area without expanding the least)
    let best_child_id = choose_best_child(node, treenode.get_children(), new_bounds);

    // Recursively keep looking for the best child, until the leaf with the smallest new area is
    // found
    choose_leaf(world, best_child_id, new_bounds, parent_id)
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

pub fn add_root_layer(world: IWorldDispatcher) -> u64 {
    // TODO
    println!("adding root layer");
    ROOT_ID
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
            let combined_area = bounds.at(i).deref().combine(bounds.at(j).deref()).area();

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

    (array![].span(), array![].span())
}

// Splits the current node, and those above it if needed
pub fn update_ancestry(
    world: IWorldDispatcher, ancestry: Span<u64>, level: usize, updated_children: Array<u64>
) -> u64 {
    // Step 1: Identify Node to update
    let mut current_node_id = *ancestry[level];
    println!("update_ancestry: {:?}", current_node_id);
    let current_treenode: RTree = get!(world, (current_node_id), RTree);
    let mut current_node: RTreeNode = current_treenode.get_node();

    // Step 2: Check if Splitting is Needed and return if not
    let current_children = current_treenode.get_children();

    // // Step 3: Remove the old node from storage, we're replacing it with 2 new ones
    delete!(world, (current_treenode));

    println!("current_children leaf: {:?}", current_children);
    println!("updated_children leaf: {:?}", updated_children);
    println!("level: {:?}", level);
    println!("current_node_id: {:?}", current_node_id);

    if updated_children.len() > 4 {
        // Maxed out children, need to split
        println!("splitting leaf: {:?}", current_node_id);
    } else {
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

    // // Step 4: distribute the new children over two collections
    // let mut new_children = array![];
    // new_children.append_span(current_children);
    // let (current_children, sibling_children) = distribute_children(new_children.span());

    // // Step 5: Calculate New Bounds
    // let current_spanningbounds = spanning_bounds(current_children);
    // let sibling_spanningbounds = spanning_bounds(sibling_children);

    // // Step 6: Create New Nodes
    // current_node.bounds = current_spanningbounds;
    // let current_node_id = current_node.pack();
    // let sibling_node = RTreeNode {
    //     bounds: sibling_spanningbounds, is_leaf: current_node.is_leaf, is_area: false
    // };
    // let sibling_node_id = sibling_node.pack();

    // set!(world, RTree { id: current_node_id, children: current_children.pack() });
    // set!(world, RTree { id: sibling_node_id, children: sibling_children.pack() });

    // // Step 7: Handle Parent Node
    // if level == 0 {
    //     // Create the new nodes under root (a new layer)

    //     // Update Root's children
    //     add_root_layer(world);
    //     //return existing_node_id;
    // } else {
    //     // TODO need to also send the replacement id of the current node.
    //     update_ancestry(world, ancestry, level - 1, sibling_node_id)
    // }
    current_node_id
}


pub fn add_area(world: IWorldDispatcher, bounds: Bounds, hint_rtree: Option<u64>) -> u64 {
    // 1. Prepare the leaf

    // TODO: use the hint to start searching deeper in the tree.

    // Step 1: Prepare the Leaf (parent, leaf)
    let (mut leaf, leafparent_id): (RTree, u64) = choose_leaf(world, ROOT_ID, bounds, ROOT_ID);
    let leafnode: RTreeNode = leaf.get_node();

    println!("adding to leaf: {:?}", leaf.id);

    // Step 2: Create New Area Node
    let new_area = RTreeNode { bounds, is_leaf: false, is_area: true };
    let new_area_id = new_area.pack();

    // Step 3: Update Parent Node, Add the area node to the parent children array
    let updated_leaf_children: Array<u64> = leaf.add_child_id(new_area_id);

    // Step 4: Handle recursive ancestor resizing
    let mut ancestors: Array<u64> = array![];
    get_ancestors(world, ref ancestors, leaf.id);

    println!("ancestors leaf: {:?}", ancestors);

    let new_leaf_id = update_ancestry(
        world,
        ancestors.span(), // ancestors
        ancestors.len() - 1, // level 
        updated_leaf_children // new id (new leaf_id can be calculated from this)
    );

    // // Step 4: Handle Node Splitting
    // if updated_leaf_children.len() > 4 {
    //     // Maxed out children, need to split
    //     println!("splitting leaf: {:?}", leaf);

    //     // Get the ancestors, so we can split ancestors if needed without repeatedly finding
    //     parent let mut ancestors: Array<u64> = array![];
    //     get_ancestors(world, ref ancestors, leaf.id);

    //     let new_parent_leaf_id = update_ancestry(
    //         world, ancestors.span(), ancestors.len() - 1, new_area_id
    //     );

    //     leaf = get!(world, (new_parent_leaf_id), RTree);
    // }

    // // Step 5: Store Updated Nodes
    // // Remove the old Leaf node
    // delete!(world, (leaf));

    // // Increase size of leaf node since it now contains our Area
    // // This also changes its id.
    // let leafnode_new = RTreeNode {
    //     bounds: leafnode.bounds.combine(bounds), is_leaf: true, is_area: false
    // };

    // leaf_new_id = leafnode_new.pack();
    // let leaf_new = RTree { id: leaf_new_id, children: updated_leaf_children.pack() };

    // // Store the new Leaf node
    // set!(world, (leaf_new));

    // // Replace parent child entry
    // let leafnode_parent: RTree = get!(world, (leafparent_id), RTree);

    // set!(
    //     world,
    //     (RTree {
    //         id: leafnode_parent.id, children: leafnode_parent.replace_child_id(leaf.id,
    //         leaf_new_id)
    //     })
    // );

    // Step 6: Return New Area ID
    new_leaf_id
}

pub fn remove_area(world: IWorldDispatcher, area_id: felt252, hint_rtree: Option<felt252>) {}

pub fn find_area(
    world: IWorldDispatcher, position: Position, area_id: Option<u64>, hint_rtree: Option<felt252>
) -> u64 {
    // FIXME this is just to make it compile for now
    0
}
