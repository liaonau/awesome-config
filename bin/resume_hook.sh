#!/bin/bash

# pulseaudio sinks and sink_inputs update
echo 'volume.update_all()' | awesome-client > /dev/null 2>&1
