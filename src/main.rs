extern crate futures;
extern crate futures_cpupool;

use futures::Future;
use futures_cpupool::CpuPool;

fn main() {
    let pool = CpuPool::new_num_cpus();

    let fut = pool.spawn_fn(|| Ok(5u32) as Result<u32, ()>)
        .map(|x: u32| x * 2)
        .map(|x: u32| println!("x = {}", x));

    let _ = fut.wait();
}
