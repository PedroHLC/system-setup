{
  services.gitlab-runner = {
    enable = true;
    services.default = {
      authenticationTokenConfigFile = "/var/persistent/secrets/gitlab-runner.env";
      dockerImage = "node:lts-alpine";
    };
  };
}
