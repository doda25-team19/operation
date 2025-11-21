operation: https://github.com/doda25-team19/operation

backend: https://github.com/doda25-team19/model-service/tree/a1

frontend: https://github.com/doda25-team19/app/tree/a1

lib: https://github.com/doda25-team19/lib-version/tree/a1



## Comments for A1:

We have implemented subtasks F1, F2, F3, F6, F7, and they are ready to be reviewed.

To run the application so far the following command should be executed in the terminal:

```
docker-compose up
```

To build, run:


docker build -t model-service .


docker build -t doda25-team19/app:latest .



To run:

docker run -p 8080:8080 -e MODEL_HOST=http://host.docker.internal:8081 app


docker run -p 8081:8081 doda25-team19/model-service:latest
