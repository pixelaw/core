pub mod apps {
    pub mod house;
    pub mod paint;
    pub mod player;
    pub mod snake;
}

pub mod core {
    pub mod actions;
    pub mod events;
    pub mod models;
    pub mod utils;
}

#[cfg(test)]
pub mod tests {
    mod apps {
        mod app_house;
        mod app_paint;
        mod app_player;
        mod app_snake;
    }
    mod core {
        mod area;
        mod base;
        mod interop;
        mod pixel_area;
        mod queue;
        mod utils;
    }
}
