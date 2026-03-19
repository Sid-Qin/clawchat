let _runtime: any = null;

export function setClawChatRuntime(runtime: any) {
  _runtime = runtime;
}

export function getClawChatRuntime(): any {
  if (!_runtime) throw new Error("ClawChat runtime not initialized");
  return _runtime;
}
