use array::ArrayTrait;

#[derive(Copy, Clone)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
struct Box {
    x: u32,
    y: u32,
    width: u32,
    height: u32,
}

impl Box {
    fn new(x: u32, y: u32, width: u32, height: u32) -> Box {
        Box { x, y, width, height }
    }

    fn contains_point(self: @Box, px: u32, py: u32) -> bool {
        px >= self.x && px <= self.x + self.width && py >= self.y && py <= self.y + self.height
    }

    fn intersects(self: @Box, other: Box) -> bool {
        !(other.x > self.x + self.width ||
        other.x + other.width < self.x ||
        other.y > self.y + self.height ||
        other.y + other.height < self.y)
    }
}

#[derive(Copy, Clone)]
#[dojo::model(namespace: "pixelaw", nomapping: true)]
struct Area {
    is_leaf: bool,
    bounding_box: Box,
    children: Array<Area>,
}

impl Area {
    fn new_leaf(bounding_box: Box) -> Area {
        Area {
            is_leaf: true,
            bounding_box,
            children: Array::new(),
        }
    }

    fn new_internal(bounding_box: Box) -> Area {
        Area {
            is_leaf: false,
            bounding_box,
            children: Array::new(),
        }
    }

    fn update_bounding_box(self: @mut Area) {
        if self.children.len() == 0 {
            return;
        }

        let mut min_x = self.children[0].bounding_box.x;
        let mut min_y = self.children[0].bounding_box.y;
        let mut max_x = self.children[0].bounding_box.x + self.children[0].bounding_box.width;
        let mut max_y = self.children[0].bounding_box.y + self.children[0].bounding_box.height;

        for child in self.children.iter() {
            min_x = min(min_x, child.bounding_box.x);
            min_y = min(min_y, child.bounding_box.y);
            max_x = max(max_x, child.bounding_box.x + child.bounding_box.width);
            max_y = max(max_y, child.bounding_box.y + child.bounding_box.height);
        }

        self.bounding_box = Box::new(min_x, min_y, max_x - min_x, max_y - min_y);
    }

    fn insert(self: @mut Area, Box: Box) {
        if self.is_leaf {
            let new_node = Area::new_leaf(Box);
            self.children.append(new_node);
            self.update_bounding_box();
            return;
        }

        // Choose the best child node for insertion (naive implementation)
        let mut best_child = @mut self.children[0];
        for child in self.children.iter_mut() {
            let current_Box = child.bounding_box.width * child.bounding_box.height;
            let best_Box = best_child.bounding_box.width * best_child.bounding_box.height;
            if current_Box < best_Box {
                best_child = child;
            }
        }

        best_child.insert(Box);
        self.update_bounding_box();
    }

    fn search(self: @Area, px: u32, py: u32) -> bool {
        if !self.bounding_box.contains_point(px, py) {
            return false;
        }

        if self.is_leaf {
            for child in self.children.iter() {
                if child.bounding_box.contains_point(px, py) {
                    return true;
                }
            }
            return false;
        }

        for child in self.children.iter() {
            if child.search(px, py) {
                return true;
            }
        }

        return false;
    }
}
