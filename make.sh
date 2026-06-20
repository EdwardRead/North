#!/bin/bash
cd gtk4ffilib && cargo build --release && cd .. && cp ./gtk4ffilib/target/release/libgtk4ffilib.so ./ && idris2 --build IdrisElm.ipkg