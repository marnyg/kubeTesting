{ ... }: {
  perSystem = { config, pkgs, ... }: {
    config = {
      just-flake.features = {
        treefmt.enable = true;
        rust.enable = true;
        convco.enable = true;
        direnv = {
          enable = true;
          justfile = ''
            reload:
              direnv reload
          '';
        };
        kubernetes = {
          enable = true;
          justfile = ''
            #start minikube
            start:
              "${pkgs.minikube}/bin/minikube" status || "${pkgs.minikube}/bin/minikube" start
              "${pkgs.kubectl}/bin/kubectl" get namespace argocd || "${pkgs.kubectl}/bin/kubectl" create namespace argocd
              "${pkgs.kubectl}/bin/kubectl" apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

              echo "Waiting for kubernetes-dashboard pod to be ready..."
              sleep 5
              "${pkgs.kubectl}/bin/kubectl" wait --namespace kubernetes-dashboard \
                --for=condition=available deployment kubernetes-dashboard-kong \
                --timeout=600s

              "${pkgs.kubectl}/bin/kubectl" -n kubernetes-dashboard port-forward service/kubernetes-dashboard-kong-proxy 8443:443 &
              echo "Kubernetes Dashboard is now accessible at http://localhost:8443"

            setup-dashboard-access:
              "${pkgs.kubectl}/bin/kubectl" create serviceaccount -n kubernetes-dashboard admin-user
              "${pkgs.kubectl}/bin/kubectl" create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user

            arogcd:
              "${pkgs.argocd}/bin/argocd" app list

            nats:
              "${pkgs.kubernetes-helm}/bin/helm" repo add nats https://nats-io.github.io/k8s/helm/charts/
              "${pkgs.kubernetes-helm}/bin/helm" install my-nats nats/nats
            secret:
              "${pkgs.kubernetes-helm}/bin/helm" repo add infisical-helm-charts 'https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/'
              "${pkgs.kubernetes-helm}/bin/helm" repo update
              "${pkgs.kubernetes-helm}/bin/helm" install --generate-name infisical-helm-charts/secrets-operator

            #vault/infisical
            #wasmcloud
            #traefik
            #cert-manager
            #grafana/loki/promtail/
            #cilium
          '';
        };
      };

      devShells.default = pkgs.mkShell
        {
          buildInputs = [ pkgs.minikube pkgs.argocd pkgs.kubernetes-helm pkgs.kubectl pkgs.k9s ];
          shellHook = config.pre-commit.installationScript;
          inputsFrom = [ config.just-flake.outputs.devShell ];
        };

      pre-commit = {
        settings.hooks.nixpkgs-fmt.enable = true;
        settings.hooks.deadnix.enable = true;
        settings.hooks.nil.enable = true;
        settings.hooks.statix.enable = true;
        settings.hooks.typos.enable = true;
        settings.hooks.commitizen.enable = true;
        settings.hooks.yamllint.enable = true;
        settings.hooks.yamllint.settings.preset = "relaxed";
        settings.hooks.statix.settings.format = "stderr";
        settings.hooks.statix.args = [ "--config" "${pkgs.writeText "conf.toml" "disabled = [ repeated_keys ]"}" ];
        settings.hooks.typos.settings.ignored-words = [ "noice" ];
        settings.hooks.typos.stages = [ "manual" ];
      };


      treefmt.config = {
        inherit (config.flake-root) projectRootFile;
        package = pkgs.treefmt;

        programs.nixpkgs-fmt.enable = true;
        programs.yamlfmt.enable = true;
      };
    };
  };
}
