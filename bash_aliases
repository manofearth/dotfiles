alias dcompose="docker-compose"
alias dcud="docker-compose up -d"

function haskell-run-here {
	docker run --name haskell -it --rm -v `pwd`:/usr/src/ -w /usr/src haskell bash
}

function projectlibre {
  if [ "$(docker ps -a -q -f name=projectlibre)" ]; then
    docker container start projectlibre
  else
    docker run -it \
      --net host \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -e DISPLAY=unix$DISPLAY \
      -v $HOME/Documents/projectlibre:/home/projectlibre \
      --device /dev/snd \
      --name projectlibre \
      manofearth/projectlibre &
  fi
}

function jupyter {
  if [[  "$(docker ps -q -f name=jupyter)" ]]; then
    echo "jupyter is already running"
  elif [[ "$(docker ps -a -q -f name=jupyter)" ]]; then
    echo "starting jupyter"
    docker container start jupyter
    sleep 5
  else
    echo "creating jupyter"
    docker run -it \
      -v $HOME/Documents/jupyter:/home/jupyter \
      -p 8888:8888 \
      --name jupyter \
      manofearth/jupyter &
  fi
  google-chrome http://localhost:8888
}

function togoals-bash {
  if [[  "$(docker ps -q -f name=togoals_python_run_1)" ]]; then
    echo "togoals_python_run_1 is already running"
  elif [[ "$(docker ps -a -q -f name=togoals_python_run_1)" ]]; then
    echo "starting togoals_python_run_1"
    docker container start -ia togoals_python_run_1
  else
    echo "creating togoals_python_run_1"
    cd ~/projects/to-goals
    docker-compose run python bash
  fi
}
