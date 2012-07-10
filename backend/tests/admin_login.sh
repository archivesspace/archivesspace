#!/bin/sh

asresponse=`curl -d "user=admin&password=admin123" 127.0.0.1:4567/auth/user/admin/login`
echo $asresponse