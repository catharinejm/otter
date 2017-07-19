extern crate futures;
extern crate futures_cpupool;
extern crate rand;

use futures_cpupool::CpuPool;
use rand::random;

use std::collections::HashMap;
use std::sync::mpsc::{Sender, channel};
use std::thread;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct ActorID(usize);

impl ActorID {
    pub fn new() -> ActorID {
        ActorID(random())
    }
}

pub trait Actor {
    type Msg: Send;

    fn pool(&self) -> &CpuPool;
}

// impl Actor {
//     fn launch() -> (Sender<(ActorID, N)>, thread::JoinHandle<()>)
//     where
//         B: Actor<Msg = N>,
//         N: Send,
//     {
//         let (tx, rx) = channel();
//         let handle = thread::spawn(move || {
//             let disp = Actor { actors: HashMap::new() };
//             loop {
//                 rx.recv().ok().and_then(|(id, msg): (ActorID, N)| {
//                     disp.actors.get(&id).map(|act: &B| act.send(msg))
//                 });
//             }
//         });
//         (tx, handle)
//     }

//     // pub fn owns(&self, id: ActorID) -> bool {
//     //     self.actors.contains_key(&id)
//     // }

//     // pub fn register(&mut self, actor: A) -> ActorID {
//     //     let mut id = ActorID::new();
//     //     while self.owns(id) {
//     //         id = ActorID::new();
//     //     }
//     //     self.actors.insert(id, actor);
//     //     id
//     // }

//     // pub fn send(&self, id: ActorID, msg: M) -> ActorResult {
//     //     if self.owns(id) {
//     //         self.tx.send((id, msg));
//     //         Ok(())
//     //     } else {
//     //         Err(ActorError::NotFound)
//     //     }
//     // }
// }
