#[allow(dead_code)]
pub struct FnTrace(&'static str);

// Putting this at the start of a function will cause it to print out the given string as an indication of when its call begins and ends. 
// Rust is cool. 
impl FnTrace {
    #[allow(dead_code)]
    pub fn new(name: &'static str) -> Self {
        println!("--> {}", name);
        Self(name)
    }
}

impl Drop for FnTrace {
    fn drop(&mut self) {
        println!("<-- {}", self.0);
    }
}
