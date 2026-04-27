#!/bin/bash

docker logs taskmanager 2>&1 | tail -30
