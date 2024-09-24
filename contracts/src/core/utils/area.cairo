use dojo::{
    utils::test::{spawn_test_world, deploy_contract},
    world::{IWorldDispatcher, IWorldDispatcherTrait}
};
use pixelaw::core::{
    utils::{Bounds, min, max, Position},
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

    println!("{} Node: {} {:?}", indent, node_id, node);
    println!("{} Children: {:?}", indent, children);

    let mut new_indent: ByteArray = "    " + indent.clone();

    for child_id in children {
        print_tree(world, *child_id, new_indent.clone());
    };
}


// Splits the current node, and those above it if needed
pub fn split_node_if_needed(
    world: IWorldDispatcher, ancestors: Span<u64>, level: usize, new_children: Span<u64>
) -> u64 {
    let node_id = *ancestors[level];

    // TODO deal with new_children

    // Load the node from storage
    let treenode: RTree = get!(world, (node_id), RTree);

    // No need to split if there are less than 4 children
    if treenode.get_children().len() < 4 {
        return 0;
    }
    println!("splitting at level {:?}, node: {:?}", level, node_id);

    if level == 0 {
        // TODO We're at root level, add a layer instead??
        return 0;
    }

    // Since we're splitting this one, the parent will gain an extra child.
    // Split parent if needed.
    let parent_id = split_node_if_needed(world, ancestors, level - 1, bounds_added);

    if parent_id > 0 {// TODO The parent changed, do something??
    }

    let parent: RTree = get!(world, (parent_id), RTree);

    // TODO split this node now, after parents were done
    // TODO Determine new bounds of this node and the new sibling

    // TODO Add a new sibling to the parent
    // TODO distribute children over current and new sibling

    node_id
}


pub fn add_area(world: IWorldDispatcher, bounds: Bounds, hint_rtree: Option<u64>) -> u64 {
    // 1. Prepare the leaf

    // TODO: use the hint to start searching deeper in the tree.
    // Fornow, Start at rootnode

    // Default output
    let mut leaf_new_id = 0;

    let (mut leaf_changing, leafnode_parent_id): (RTree, u64) = choose_leaf(
        world, ROOT_ID, bounds, ROOT_ID
    );
    let leafnode_changing: RTreeNode = leaf_changing.get_node();

    let new_area = RTreeNode { bounds, is_leaf: true, is_area: true };
    let new_area_id = new_area.pack();

    // 2. Add the area node
    let mut children: Span<u64> = leaf_changing.get_children();

    // Add the child
    let updated_leaf_children = leaf_changing.add_child_id(new_area_id);


    if children.len() > 4 {
        // Maxed out children, need to split
        println!("splitting leaf_changing: {:?}", leaf_changing);

        // Get the ancestors, so we can split up
        let mut ancestors: Array<u64> = array![];
        get_ancestors(world, ref ancestors, leaf_changing.id);

        let new_parent_leaf_id = split_node_if_needed(
            world, ancestors.span(), ancestors.len() - 1, bounds
        );
        leaf_changing = get!(world, (new_parent_leaf_id), RTree);
    }


    // Remove the old Leaf node
    delete!(world, (leaf_changing));

    // Increase size of leaf node since it now contains our Area
    // This also changes its id.
    let leafnode_new = RTreeNode {
        bounds: leafnode_changing.bounds.combine(bounds), is_leaf: true, is_area: false
    };

    leaf_new_id = leafnode_new.pack();
    let leaf_new = RTree { id: leaf_new_id, children: updated_leaf_children };

    // Store the new Leaf node
    set!(world, (leaf_new));

    // Replace parent child entry
    let leafnode_parent = get!(world, (leafnode_parent_id), RTree);
    set!(
        world,
        (RTree {
            id: leafnode_parent.id,
            children: leafnode_parent.replace_child_id(leaf_changing.id, leaf_new_id)
        })
    );

    new_area_id
}

pub fn remove_area(world: IWorldDispatcher, area_id: felt252, hint_rtree: Option<felt252>) {}

pub fn find_area(
    world: IWorldDispatcher, position: Position, area_id: Option<u64>, hint_rtree: Option<felt252>
) -> u64 {
    // FIXME this is just to make it compile for now
    0
}
