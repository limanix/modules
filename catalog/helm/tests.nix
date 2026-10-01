{ coexistence, defaultVersionEntryPoint, ... }:
{
  evaluation = {
    defaultEntryPoint = defaultVersionEntryPoint;
    coexistence = coexistence [ "helm" ];
  };
}
