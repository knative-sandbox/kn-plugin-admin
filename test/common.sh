# Copyright 2020 The Knative Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source $(dirname $0)/../vendor/knative.dev/hack/e2e-tests.sh

function cluster_setup() {
  header "Installing client"
  local kn_build=$(mktemp -d)
  local failed=""
  pushd "$kn_build"
  git clone https://github.com/knative/client . || failed="Cannot clone kn githup repo"
  hack/build.sh -f || failed="error while builing kn"
  cp kn /usr/local/bin/kn || failed="can't copy kn to /usr/local/bin"
  chmod a+x /usr/local/bin/kn || failed="can't chmod kn"
  if [ -n "$failed" ]; then
     echo "ERROR: $failed"
     exit 1
  fi
  popd
  rm -rf "$kn_build"

  header "Building plugin"
  ${REPO_ROOT_DIR}/hack/build.sh -f || return 1
}

function knative_setup() {
  local serving_version=${KNATIVE_SERVING_VERSION:-latest}
  header "Installing Knative Serving (${serving_version})"

  if [ "${serving_version}" = "latest" ]; then
    start_latest_knative_serving
  else
    start_release_knative_serving "${serving_version}"
  fi

  local eventing_version=${KNATIVE_EVENTING_VERSION:-latest}
  header "Installing Knative Eventing (${eventing_version})"

  if [ "${eventing_version}" = "latest" ]; then
    start_latest_knative_eventing

    subheader "Installing eventing extension: sugar-controller (${eventing_version})"
    # install the sugar controller
    kubectl apply --filename https://storage.googleapis.com/knative-nightly/eventing/latest/eventing-sugar-controller.yaml
    wait_until_pods_running knative-eventing || return 1

  else
    start_release_knative_eventing "${eventing_version}"

    subheader "Installing eventing extension: sugar-controller (${eventing_version})"
    # install the sugar controller
    kubectl apply --filename https://storage.googleapis.com/knative-releases/eventing/previous/v${eventing_version}/eventing-sugar-controller.yaml
    wait_until_pods_running knative-eventing || return 1
  fi
}
