# tensorflow-serving-centos-dockerfile
tensorflow serving r2.8 实际docker build 过程中建议分多个state 进行构建，提高成功率，bazel 编译过程中需要下载很多文件，网络需要翻墙环境。
## 1 强烈建议将tensorflow serving 源码文件  serving/tensorflow_serving/repo.bzl  所对应的urls = [
        "https://mirror.bazel.build/github.com/tensorflow/tensorflow/archive/%s.tar.gz" % git_commit,
        "https://github.com/tensorflow/tensorflow/archive/%s.tar.gz" % git_commit,
    ]
文件提前下载到自己构建的http 服务器上，上面文件路径中% git_commit 替换成 serving/WORKSPACE 文件中
```
tensorflow_http_archive(
    name = "org_tensorflow",
    sha256 = "3e6c98de0842520a65978549be7b1b6061080ecf9fa9f3a87739e19a0447a85c",
    git_commit = "1f8f692143aa9a42c55f8b35d09aeed93bdab66e",
)```
中的git_commit 值(不同的版本，对应的值是不同的)

## 2 源码文件中 serving/tensorflow_serving/workspace.bzl  中需要的文件也建议提前下载并上传自建的http 服务器上，提高编译成功率
