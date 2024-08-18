#!/bin/bash

sudo systemctl stop docker
sudo systemctl start docker
sudo systemctl status docker

