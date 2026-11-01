# Self-hosted AI chat: sandboxes on Kubernetes

> Local draft. Release-matched API/runtime images and the patched OpenSandbox
> server image must be supplied and validated before publication. The on-premise
> runtime is not yet published separately.

Use this setup for **BYOK with self-hosted Chat**. Configure Chat, models and
storage using [Self-hosted AI chat setup](https://docs.uibakery.io/on-premise/additional-configurations/self-hosted-ai-chat-setup),
then add the services below. Managed Chat needs no local sandboxes.

**No Helm, configuration bundle or additional folders are required.** Create one
`sandboxes.yaml` from the block below; keys will be stored in Kubernetes Secrets.
Use the existing cluster and Bakery namespace. Requirements:

- Linux/amd64 nodes, an enforcing NetworkPolicy CNI and administrative CRD/RBAC access.
- A default StorageClass for an 8 GiB provider volume.
- Admission policy allowing the trusted OpenSandbox init/egress privileges.

The preset keeps **one agent and one build ready**; allow roughly 3 GiB of extra
memory requests including workloads and control services. It uses `runc` with
native egress enforcement and a shared host kernel. User-code containers receive
no host mounts, Docker socket or Kubernetes credentials. If OpenSandbox already
exists, check CRD/controller compatibility before installing.

## 1. Create one manifest

Copy the following block into `sandboxes.yaml`. All CRDs, provider/API resources,
RBAC, quotas and network policies are included.

<details>
<summary>sandboxes.yaml — complete manifest</summary>

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.18.0
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: batchsandboxes.sandbox.opensandbox.io
spec:
  group: sandbox.opensandbox.io
  names:
    kind: BatchSandbox
    listKind: BatchSandboxList
    plural: batchsandboxes
    shortNames:
    - bsbx
    singular: batchsandbox
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: The desired number of pods.
      jsonPath: .spec.replicas
      name: DESIRED
      type: integer
    - description: The number of currently all pods.
      jsonPath: .status.replicas
      name: TOTAL
      type: integer
    - description: The number of currently all allocated pods.
      jsonPath: .status.allocated
      name: ALLOCATED
      type: integer
    - description: The number of currently all ready pods.
      jsonPath: .status.ready
      name: Ready
      type: integer
    - description: The number of currently all running tasks.
      jsonPath: .status.taskRunning
      name: TASK_RUNNING
      priority: 1
      type: integer
    - description: The number of currently all succeed tasks.
      jsonPath: .status.taskSucceed
      name: TASK_SUCCEED
      priority: 1
      type: integer
    - description: The number of currently all failed tasks.
      jsonPath: .status.taskFailed
      name: TASK_FAILED
      priority: 1
      type: integer
    - description: The number of currently all unknown tasks.
      jsonPath: .status.taskUnknown
      name: TASK_UNKNOWN
      priority: 1
      type: integer
    - description: sandbox expire time
      jsonPath: .spec.expireTime
      name: EXPIRE
      type: string
    - description: CreationTimestamp is a timestamp representing the server time when this object was created. It
        is not guaranteed to be set in happens-before order across separate operations. Clients may not set this
        value. It is represented in RFC3339 form and is in UTC.
      jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: BatchSandbox is the Schema for the batchsandboxes API.
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: BatchSandboxSpec defines the desired state of BatchSandbox.
            properties:
              expireTime:
                description: |-
                  ExpireTime - Absolute time when the batch-sandbox is deleted.
                  If a time in the past is provided, the batch-sandbox will be deleted immediately.
                format: date-time
                type: string
              pause:
                description: |-
                  Pause is the pause/resume intent written by Server and executed by Controller.
                  nil = no operation / server retry bridge
                  true = request Pause
                  false = request Resume
                  Controller never clears this field; Server may temporarily patch nil to force a new generation for retries.
                type: boolean
              poolRef:
                description: |-
                  PoolRef references the Pool resource name for pooled sandbox creation.
                  Mutually exclusive with Template - use PoolRef for pool-based allocation or Template for direct sandbox creation.
                type: string
              replicas:
                default: 1
                description: Replicas is the number of desired replicas.
                format: int32
                minimum: 0
                type: integer
              shardPatches:
                description: ShardPatches indicates patching to the Template for BatchSandbox.
                x-kubernetes-preserve-unknown-fields: true
              shardTaskPatches:
                description: ShardTaskPatches indicates patching to the TaskTemplate for individual Task.
                x-kubernetes-preserve-unknown-fields: true
              taskResourcePolicyWhenCompleted:
                default: Retain
                description: |-
                  TaskResourcePolicyWhenCompleted specifies how resources should be handled once a task reaches a completed state (SUCCEEDED or FAILED).
                  - Retain: Keep the resources until the BatchSandbox is deleted.
                  - Release: Free the resources immediately when the task completes.
                type: string
              taskTemplate:
                description: |-
                  Task is a custom task spec that is automatically dispatched after the sandbox is successfully created.
                  The Sandbox is responsible for managing the lifecycle of the task.
                x-kubernetes-preserve-unknown-fields: true
              template:
                description: Template describes the pods that will be created.
                x-kubernetes-preserve-unknown-fields: true
            required:
            - replicas
            type: object
          status:
            description: BatchSandboxStatus defines the observed state of BatchSandbox.
            properties:
              allocated:
                description: "\tAllocated is the number of actual scheduled Pod"
                format: int32
                type: integer
              conditions:
                description: Conditions records lifecycle and operational state details.
                items:
                  description: BatchSandboxCondition represents a condition of a BatchSandbox
                  properties:
                    lastTransitionTime:
                      description: LastTransitionTime is the last time the condition transitioned
                      format: date-time
                      type: string
                    message:
                      description: Message is a human-readable message about the condition
                      type: string
                    reason:
                      description: Reason is a brief reason for the condition
                      type: string
                    status:
                      description: Status is the condition status
                      enum:
                      - 'True'
                      - 'False'
                      type: string
                    type:
                      description: Type is the condition type
                      enum:
                      - Ready
                      - Progressing
                      - Paused
                      - PauseFailed
                      - ResumeFailed
                      - PodFailed
                      - PoolAllocationPending
                      type: string
                  required:
                  - status
                  - type
                  type: object
                type: array
                x-kubernetes-list-map-keys:
                - type
                x-kubernetes-list-type: map
              observedGeneration:
                description: |-
                  ObservedGeneration is the most recent generation observed for this BatchSandbox. It corresponds to the
                  BatchSandbox's generation, which is updated on mutation by the API Server.
                format: int64
                type: integer
              pauseObservedGeneration:
                description: |-
                  PauseObservedGeneration is the generation most recently ACKed by the Controller
                  when entering pause/resume dispatch logic. Written immediately to prevent reentry (idempotent gating).
                format: int64
                type: integer
              phase:
                description: |-
                  Phase is the overall phase of the BatchSandbox, aggregated and written by Controller.
                  Server reads this field directly without combining multiple fields.
                enum:
                - Pending
                - Succeed
                - Pausing
                - Paused
                - Resuming
                - Failed
                type: string
              ready:
                description: "\tReady is the number of actual Ready Pod"
                format: int32
                type: integer
              replicas:
                description: Replicas is the number of actual Pods
                format: int32
                type: integer
              taskFailed:
                description: TaskFailed is the number of Failed task
                format: int32
                type: integer
              taskLastErrorMessage:
                description: |-
                  TaskLastErrorMessage holds the most recent error message from a failed task.
                  This includes lifecycle hook failures (e.g., ossfs mount timeout or error output).
                type: string
              taskPending:
                description: TaskPending is the number of Pending task which is unassigned
                format: int32
                type: integer
              taskRunning:
                description: TaskRunning is the number of Running task
                format: int32
                type: integer
              taskSucceed:
                description: TaskSucceed is the number of Succeed task
                format: int32
                type: integer
              taskUnknown:
                description: TaskUnknown is the number of Unknown task
                format: int32
                type: integer
            required:
            - allocated
            - ready
            - replicas
            - taskFailed
            - taskPending
            - taskRunning
            - taskSucceed
            - taskUnknown
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.18.0
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: pools.sandbox.opensandbox.io
spec:
  group: sandbox.opensandbox.io
  names:
    kind: Pool
    listKind: PoolList
    plural: pools
    singular: pool
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - description: The number of all nodes in pool.
      jsonPath: .status.total
      name: TOTAL
      type: integer
    - description: The number of allocated nodes in pool.
      jsonPath: .status.allocated
      name: ALLOCATED
      type: integer
    - description: The number of available nodes in pool.
      jsonPath: .status.available
      name: AVAILABLE
      type: integer
    - description: The number of nodes updated to the latest revision.
      jsonPath: .status.updated
      name: UPDATED
      type: integer
    - jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        description: Pool is the Schema for the pools API.
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: PoolSpec defines the desired state of Pool.
            properties:
              capacitySpec:
                description: CapacitySpec controls the size of the resource pool.
                properties:
                  bufferMax:
                    description: BufferMax is the maximum number of nodes kept in the warm buffer.
                    format: int32
                    minimum: 0
                    type: integer
                  bufferMin:
                    description: BufferMin is the minimum number of nodes that must remain in the buffer.
                    format: int32
                    minimum: 0
                    type: integer
                  poolMax:
                    description: PoolMax is the maximum total number of nodes allowed in the entire pool.
                    format: int32
                    minimum: 0
                    type: integer
                  poolMin:
                    description: PoolMin is the minimum total size of the pool.
                    format: int32
                    minimum: 0
                    type: integer
                required:
                - bufferMax
                - bufferMin
                - poolMax
                - poolMin
                type: object
              recycleStrategy:
                description: |-
                  RecycleStrategy controls how pods are handled when returned to the pool.
                  Default is Delete, which deletes the pod.
                  Restart strategy restarts the pod containers instead of deleting.
                properties:
                  type:
                    default: Delete
                    description: |-
                      Type specifies the recycle policy type.
                      Default is Delete.
                    enum:
                    - Delete
                    - Restart
                    - Noop
                    type: string
                type: object
              scaleStrategy:
                description: ScaleStrategy controls the scaling behavior.
                properties:
                  maxUnavailable:
                    anyOf:
                    - type: integer
                    - type: string
                    description: |-
                      MaxUnavailable is the maximum number of pods that can be unavailable during scaling.
                      Can be an absolute number (ex: 5) or a percentage of desired pods (ex: "20%").
                      Defaults to 25%.
                    x-kubernetes-int-or-string: true
                type: object
              template:
                description: Pod Template used to create pre-warmed nodes in the pool.
                x-kubernetes-preserve-unknown-fields: true
              updateStrategy:
                description: UpdateStrategy controls how pool pods are updated when the template changes.
                properties:
                  maxUnavailable:
                    anyOf:
                    - type: integer
                    - type: string
                    description: |-
                      MaxUnavailable is the maximum number of pods that can be unavailable during an update.
                      Can be an absolute number (ex: 5) or a percentage of desired pods (ex: "20%").
                      Defaults to 25%.
                    x-kubernetes-int-or-string: true
                type: object
            required:
            - capacitySpec
            type: object
          status:
            description: PoolStatus defines the observed state of Pool.
            properties:
              allocated:
                description: Allocated is the number of nodes currently allocated to sandboxes.
                format: int32
                type: integer
              available:
                description: Available is the number of nodes currently available in the pool.
                format: int32
                type: integer
              observedGeneration:
                description: |-
                  ObservedGeneration is the most recent generation observed for this BatchSandbox. It corresponds to the
                  BatchSandbox's generation, which is updated on mutation by the API Server.
                format: int64
                type: integer
              revision:
                description: Revision is the latest version of pool
                type: string
              total:
                description: Total is the total number of nodes in the pool.
                format: int32
                type: integer
              updated:
                description: Updated is the number of nodes that have been updated to the latest revision.
                format: int32
                type: integer
            required:
            - allocated
            - available
            - revision
            - total
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.18.0
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: sandboxsnapshots.sandbox.opensandbox.io
spec:
  group: sandbox.opensandbox.io
  names:
    kind: SandboxSnapshot
    listKind: SandboxSnapshotList
    plural: sandboxsnapshots
    shortNames:
    - sbxsnap
    singular: sandboxsnapshot
  scope: Namespaced
  versions:
  - additionalPrinterColumns:
    - jsonPath: .status.phase
      name: PHASE
      type: string
    - jsonPath: .spec.sandboxName
      name: SANDBOX
      type: string
    - jsonPath: .metadata.creationTimestamp
      name: AGE
      type: date
    name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: |-
              SandboxSnapshotSpec defines the desired state of SandboxSnapshot.
              Pure atomic capability: caller fills spec, Controller only reads spec.
              Registry/snapshotPushSecret/snapshotType come from Controller Manager startup params.
            properties:
              sandboxName:
                description: |-
                  SandboxName is the name of the target BatchSandbox (same namespace as SandboxSnapshot).
                  Controller uses this to find BatchSandbox -> find Pod -> dispatch commit Job.
                type: string
            required:
            - sandboxName
            type: object
          status:
            description: |-
              SandboxSnapshotStatus defines the observed state of SandboxSnapshot.
              Status is written by Controller, read-only for callers.
            properties:
              conditions:
                description: Conditions records the readiness or failure of the snapshot.
                items:
                  description: SandboxSnapshotCondition represents a condition of a SandboxSnapshot.
                  properties:
                    lastTransitionTime:
                      description: LastTransitionTime is the last time the condition transitioned.
                      format: date-time
                      type: string
                    message:
                      description: Message is a human-readable message about the condition.
                      type: string
                    reason:
                      description: Reason is a brief reason for the condition.
                      type: string
                    status:
                      description: Status is the condition status.
                      enum:
                      - 'True'
                      - 'False'
                      type: string
                    type:
                      description: Type is the condition type.
                      enum:
                      - Ready
                      - Failed
                      type: string
                  required:
                  - status
                  - type
                  type: object
                type: array
                x-kubernetes-list-map-keys:
                - type
                x-kubernetes-list-type: map
              containers:
                description: Containers holds per-container snapshot results, filled after Succeed.
                items:
                  description: ContainerSnapshot records the snapshot result for a single container.
                  properties:
                    containerName:
                      description: ContainerName is the name of the container.
                      type: string
                    imageDigest:
                      description: ImageDigest is the config digest of the pushed snapshot image.
                      type: string
                    imageUri:
                      description: ImageURI is the snapshot image URI for this container.
                      type: string
                  required:
                  - containerName
                  - imageUri
                  type: object
                type: array
              format:
                description: |-
                  Format identifies the snapshot representation. Empty means rootfs-v1 for
                  backward compatibility with snapshots created before this field existed.
                enum:
                - rootfs-v1
                - qemu-v1
                type: string
              observedGeneration:
                description: ObservedGeneration is the most recent spec generation observed by the Controller.
                format: int64
                type: integer
              phase:
                description: Phase indicates the current phase of the snapshot.
                enum:
                - Pending
                - Committing
                - Succeed
                - Failed
                type: string
              sourceNodeName:
                description: SourceNodeName is the node where the source Pod runs (for Job scheduling).
                type: string
              sourcePodName:
                description: SourcePodName is the name of the source Pod (resolved by Controller).
                type: string
              virtualMachine:
                description: VirtualMachine contains the QEMU VM state artifact for qemu-v1 snapshots.
                properties:
                  compatibility:
                    description: Compatibility contains the restore compatibility summary.
                    properties:
                      architecture:
                        description: Architecture is the guest host architecture, for example amd64.
                        type: string
                      cpuModel:
                        description: CPUModel is the configured virtual CPU model.
                        type: string
                      machineType:
                        description: MachineType is the versioned QEMU machine type.
                        type: string
                      memoryBytes:
                        description: MemoryBytes is the configured guest RAM in bytes.
                        format: int64
                        minimum: 1
                        type: integer
                      qemuConfigDigest:
                        description: QEMUConfigDigest identifies the normalized QEMU launch configuration.
                        type: string
                      qemuVersion:
                        description: QEMUVersion is the source QEMU version string.
                        type: string
                      requiredNodeClass:
                        description: RequiredNodeClass optionally constrains restore to a compatible node class.
                        type: string
                      vcpus:
                        description: VCPUs is the number of virtual CPUs.
                        format: int32
                        minimum: 1
                        type: integer
                    required:
                    - architecture
                    - cpuModel
                    - machineType
                    - memoryBytes
                    - qemuConfigDigest
                    - qemuVersion
                    - vcpus
                    type: object
                  compression:
                    description: Compression identifies the payload compression algorithm.
                    enum:
                    - zstd
                    type: string
                  imageDigest:
                    description: ImageDigest is the digest of the pushed standard container image.
                    type: string
                  imageUri:
                    description: ImageURI is the repository and tag used when the VM state image was pushed.
                    type: string
                  manifestDigest:
                    description: ManifestDigest identifies the compatibility manifest stored in the image.
                    type: string
                  payloadDigest:
                    description: PayloadDigest is the digest of the compressed VM state payload.
                    type: string
                  sizeBytes:
                    description: SizeBytes is the compressed VM state payload size.
                    format: int64
                    minimum: 0
                    type: integer
                required:
                - compatibility
                - compression
                - imageDigest
                - imageUri
                - manifestDigest
                - payloadDigest
                - sizeBytes
                type: object
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.20.1
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: sandboxpools.sandbox.fast.io
spec:
  group: sandbox.fast.io
  names:
    kind: SandboxPool
    listKind: SandboxPoolList
    plural: sandboxpools
    singular: sandboxpool
  scope: Namespaced
  versions:
  - name: v1alpha2
    schema:
      openAPIV3Schema:
        description: SandboxPool is the Schema for the sandboxpools API.
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: SandboxPoolSpec defines the desired state of SandboxPool.
            properties:
              actionHandlers:
                description: |-
                  ActionHandlers are Pod-local HTTP receivers used by ordered per-Sandbox
                  Action Bindings.
                items:
                  description: ActionHandler declares one Pod-local HTTP receiver served on loopback.
                  properties:
                    hooks:
                      description: |-
                        Hooks selects the lifecycle checkpoints delivered to this Handler. An
                        empty list makes the Handler config-only: it receives SetBinding and
                        RemoveBinding but no lifecycle Hook calls.
                      items:
                        description: |-
                          LifecycleHook is a versioned Fastlet-local Sandbox lifecycle checkpoint.
                          It is intentionally a string alias so future hooks do not require changing
                          the CRD shape. ValidateActionHandlers rejects names unsupported by this
                          Fastlet version instead of silently ignoring them.
                        type: string
                      maxItems: 16
                      type: array
                      x-kubernetes-list-type: set
                    name:
                      maxLength: 63
                      pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$
                      type: string
                    targetHTTPPort:
                      format: int32
                      maximum: 65535
                      minimum: 1
                      type: integer
                  required:
                  - name
                  - targetHTTPPort
                  type: object
                maxItems: 16
                type: array
                x-kubernetes-list-map-keys:
                - name
                x-kubernetes-list-type: map
              capacity:
                description: PoolCapacity describes the sizing policy of the fastlet pool.
                properties:
                  bufferMax:
                    format: int32
                    minimum: 0
                    type: integer
                  bufferMin:
                    format: int32
                    minimum: 0
                    type: integer
                  poolMax:
                    format: int32
                    minimum: 0
                    type: integer
                  poolMin:
                    format: int32
                    minimum: 0
                    type: integer
                required:
                - bufferMax
                - bufferMin
                - poolMax
                - poolMin
                type: object
              fastletTemplate:
                description: |-
                  FastletTemplate is intentionally preserved as a Kubernetes-native pod
                  template. Fast Sandbox validates the platform-owned fields separately.
                x-kubernetes-preserve-unknown-fields: true
              infraComponents:
                description: |-
                  InfraComponents are compiled into an immutable revision. Updating this
                  list rolls Fastlets; existing Sandboxes remain on their admitted revision.
                items:
                  description: |-
                    InfraComponent injects one artifact-backed managed process with one public
                    named endpoint. host-process components are declared for revision,
                    Fastlet-side readiness probing, and routing purposes only: they carry no
                    artifact and are deployed by fastletTemplate in the Pod network namespace.
                  properties:
                    artifact:
                      description: Artifact is required unless delivery selects host-process.
                      properties:
                        mappings:
                          items:
                            description: |-
                              InfraArtifactMapping maps one final file or directory from the verified
                              artifact root to one final path in the Sandbox.
                            properties:
                              sourcePath:
                                pattern: ^/
                                type: string
                              targetPath:
                                pattern: ^/\.fast/components/
                                type: string
                            required:
                            - sourcePath
                            - targetPath
                            type: object
                          maxItems: 64
                          minItems: 1
                          type: array
                        source:
                          description: InfraArtifactSource contains exactly one immutable source.
                          properties:
                            archive:
                              description: InfraArtifactArchive selects one immutable gzip-compressed tar archive.
                              properties:
                                sha256:
                                  pattern: ^[a-f0-9]{64}$
                                  type: string
                                url:
                                  pattern: ^https://
                                  type: string
                              required:
                              - sha256
                              - url
                              type: object
                            image:
                              description: |-
                                InfraArtifactImage selects an immutable OCI image or index as an artifact
                                carrier. Fast Sandbox injects mapped files and never starts this image.
                              properties:
                                reference:
                                  pattern: ^.+@sha256:[a-f0-9]{64}$
                                  type: string
                              required:
                              - reference
                              type: object
                          type: object
                      required:
                      - mappings
                      - source
                      type: object
                    delivery:
                      description: |-
                        InfraDeliveryMode selects an explicit delivery path for one Infra Component.
                        An empty value selects the runtime-defaulted delivery mode. host-process is
                        the only explicitly selectable mode today.
                      enum:
                      - host-process
                      type: string
                    endpoint:
                      description: InfraEndpoint is the single public endpoint of a component.
                      properties:
                        port:
                          format: int32
                          maximum: 65535
                          minimum: 1
                          type: integer
                        protocol:
                          enum:
                          - HTTP
                          type: string
                      required:
                      - port
                      - protocol
                      type: object
                    name:
                      maxLength: 63
                      pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$
                      type: string
                    process:
                      description: InfraProcess defines the process supervised inside the user Sandbox.
                      properties:
                        command:
                          items:
                            type: string
                          minItems: 1
                          type: array
                        env:
                          additionalProperties:
                            type: string
                          type: object
                        healthCheck:
                          description: InfraHealthCheck contains exactly one probe kind.
                          properties:
                            httpGet:
                              description: InfraHTTPGet is an HTTP readiness probe on the component endpoint.
                              properties:
                                path:
                                  pattern: ^/
                                  type: string
                              required:
                              - path
                              type: object
                            tcpConnect:
                              description: InfraTCPConnect selects a TCP connect readiness probe.
                              type: object
                            timeoutSeconds:
                              default: 10
                              format: int32
                              maximum: 300
                              minimum: 1
                              type: integer
                          type: object
                        restartPolicy:
                          default: OnFailure
                          description: InfraRestartPolicy controls process restart after exit.
                          enum:
                          - Never
                          - OnFailure
                          - Always
                          type: string
                      required:
                      - command
                      - healthCheck
                      type: object
                  required:
                  - endpoint
                  - name
                  - process
                  type: object
                maxItems: 16
                type: array
                x-kubernetes-list-map-keys:
                - name
                x-kubernetes-list-type: map
              maxSandboxesPerPod:
                format: int32
                minimum: 1
                type: integer
              runtime:
                description: |-
                  Runtime selects one immutable, platform-owned runtime profile.
                  Immutability is convention-only: these CRDs ship without CEL
                  (x-kubernetes-validations) so legacy (< 1.25) API servers can load
                  them, and enforcement lives in Go (pool reconciler validation).
                enum:
                - container
                - gvisor
                - kata-qemu
                - kata-clh
                - kata-fc
                - kata-dragonball
                - firecracker
                type: string
              sandboxResources:
                description: |-
                  SandboxResources is the immutable resource profile applied to each
                  Sandbox created from this Pool. As with Runtime, immutability is
                  convention-only: no CEL rule enforces it at the API server.
                properties:
                  cpu:
                    anyOf:
                    - type: integer
                    - type: string
                    pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                    x-kubernetes-int-or-string: true
                  memory:
                    anyOf:
                    - type: integer
                    - type: string
                    pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                    x-kubernetes-int-or-string: true
                  pids:
                    format: int64
                    minimum: 1
                    type: integer
                required:
                - cpu
                - memory
                - pids
                type: object
              warmImages:
                description: |-
                  WarmImages are asynchronously pulled and protected from ordinary cache GC.
                  Fastlet readiness does not wait for this list to finish warming.
                items:
                  type: string
                maxItems: 128
                type: array
            required:
            - capacity
            - fastletTemplate
            - maxSandboxesPerPod
            - runtime
            - sandboxResources
            type: object
          status:
            description: SandboxPoolStatus defines the observed state of SandboxPool.
            properties:
              busyFastlets:
                format: int32
                type: integer
              conditions:
                items:
                  description: Condition contains details for one aspect of the current state of this API Resource.
                  properties:
                    lastTransitionTime:
                      description: |-
                        lastTransitionTime is the last time the condition transitioned from one status to another.
                        This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.
                      format: date-time
                      type: string
                    message:
                      description: |-
                        message is a human readable message indicating details about the transition.
                        This may be an empty string.
                      maxLength: 32768
                      type: string
                    observedGeneration:
                      description: |-
                        observedGeneration represents the .metadata.generation that the condition was set based upon.
                        For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date
                        with respect to the current state of the instance.
                      format: int64
                      minimum: 0
                      type: integer
                    reason:
                      description: |-
                        reason contains a programmatic identifier indicating the reason for the condition's last transition.
                        Producers of specific condition types may define expected values and meanings for this field,
                        and whether the values are considered a guaranteed API.
                        The value should be a CamelCase string.
                        This field may not be empty.
                      maxLength: 1024
                      minLength: 1
                      pattern: ^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_])?$
                      type: string
                    status:
                      description: status of the condition, one of True, False, Unknown.
                      enum:
                      - 'True'
                      - 'False'
                      - Unknown
                      type: string
                    type:
                      description: type of condition in CamelCase or in foo.example.com/CamelCase.
                      maxLength: 316
                      pattern: ^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$
                      type: string
                  required:
                  - lastTransitionTime
                  - message
                  - reason
                  - status
                  - type
                  type: object
                type: array
              currentPods:
                format: int32
                type: integer
              fastletRevision:
                type: string
              idleFastlets:
                format: int32
                type: integer
              infraRevision:
                type: string
              observedGeneration:
                format: int64
                type: integer
              preparedFastlets:
                format: int32
                type: integer
              readyPods:
                format: int32
                type: integer
              runtimeRevision:
                type: string
              warmImages:
                items:
                  description: WarmImageStatus aggregates cache state for one configured warm image.
                  properties:
                    cachedFastlets:
                      format: int32
                      type: integer
                    desiredFastlets:
                      format: int32
                      type: integer
                    failedFastlets:
                      format: int32
                      type: integer
                    image:
                      type: string
                    lastError:
                      type: string
                    observedGeneration:
                      format: int64
                      type: integer
                    pullingFastlets:
                      format: int32
                      type: integer
                  required:
                  - image
                  type: object
                type: array
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.20.1
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: sandboxes.sandbox.fast.io
spec:
  group: sandbox.fast.io
  names:
    kind: Sandbox
    listKind: SandboxList
    plural: sandboxes
    singular: sandbox
  scope: Namespaced
  versions:
  - name: v1alpha2
    schema:
      openAPIV3Schema:
        description: Sandbox is the Schema for the sandboxes API.
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: SandboxSpec defines the desired state of Sandbox.
            properties:
              actionBindings:
                description: ActionBindings is atomic because its order defines Handler invocation order.
                items:
                  properties:
                    handler:
                      maxLength: 63
                      pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$
                      type: string
                    input:
                      description: |-
                        Input is opaque Handler-owned data. Fast Sandbox preserves the UTF-8
                        bytes exactly and never parses or canonicalizes its contents.
                      maxLength: 65536
                      type: string
                  required:
                  - handler
                  - input
                  type: object
                maxItems: 16
                type: array
                x-kubernetes-list-type: atomic
              args:
                items:
                  type: string
                type: array
              command:
                items:
                  type: string
                type: array
              envs:
                items:
                  description: EnvVar represents an environment variable present in a Container.
                  properties:
                    name:
                      description: |-
                        Name of the environment variable.
                        May consist of any printable ASCII characters except '='.
                      type: string
                    value:
                      description: |-
                        Variable references $(VAR_NAME) are expanded
                        using the previously defined environment variables in the container and
                        any service environment variables. If a variable cannot be resolved,
                        the reference in the input string will be unchanged. Double $$ are reduced
                        to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.
                        "$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)".
                        Escaped references will never be expanded, regardless of whether the variable
                        exists or not.
                        Defaults to "".
                      type: string
                    valueFrom:
                      description: Source for the environment variable's value. Cannot be used if value is not empty.
                      properties:
                        configMapKeyRef:
                          description: Selects a key of a ConfigMap.
                          properties:
                            key:
                              description: The key to select.
                              type: string
                            name:
                              default: ''
                              description: |-
                                Name of the referent.
                                This field is effectively required, but due to backwards compatibility is
                                allowed to be empty. Instances of this type with an empty value here are
                                almost certainly wrong.
                                More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
                              type: string
                            optional:
                              description: Specify whether the ConfigMap or its key must be defined
                              type: boolean
                          required:
                          - key
                          type: object
                          x-kubernetes-map-type: atomic
                        fieldRef:
                          description: |-
                            Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,
                            spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.
                          properties:
                            apiVersion:
                              description: Version of the schema the FieldPath is written in terms of, defaults
                                to "v1".
                              type: string
                            fieldPath:
                              description: Path of the field to select in the specified API version.
                              type: string
                          required:
                          - fieldPath
                          type: object
                          x-kubernetes-map-type: atomic
                        fileKeyRef:
                          description: |-
                            FileKeyRef selects a key of the env file.
                            Requires the EnvFiles feature gate to be enabled.
                          properties:
                            key:
                              description: |-
                                The key within the env file. An invalid key will prevent the pod from starting.
                                The keys defined within a source may consist of any printable ASCII characters except '='.
                                During Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters.
                              type: string
                            optional:
                              default: false
                              description: |-
                                Specify whether the file or its key must be defined. If the file or key
                                does not exist, then the env var is not published.
                                If optional is set to true and the specified key does not exist,
                                the environment variable will not be set in the Pod's containers.

                                If optional is set to false and the specified key does not exist,
                                an error will be returned during Pod creation.
                              type: boolean
                            path:
                              description: |-
                                The path within the volume from which to select the file.
                                Must be relative and may not contain the '..' path or start with '..'.
                              type: string
                            volumeName:
                              description: The name of the volume mount containing the env file.
                              type: string
                          required:
                          - key
                          - path
                          - volumeName
                          type: object
                          x-kubernetes-map-type: atomic
                        resourceFieldRef:
                          description: |-
                            Selects a resource of the container: only resources limits and requests
                            (limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.
                          properties:
                            containerName:
                              description: 'Container name: required for volumes, optional for env vars'
                              type: string
                            divisor:
                              anyOf:
                              - type: integer
                              - type: string
                              description: Specifies the output format of the exposed resources, defaults to "1"
                              pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                              x-kubernetes-int-or-string: true
                            resource:
                              description: 'Required: resource to select'
                              type: string
                          required:
                          - resource
                          type: object
                          x-kubernetes-map-type: atomic
                        secretKeyRef:
                          description: Selects a key of a secret in the pod's namespace
                          properties:
                            key:
                              description: The key of the secret to select from.  Must be a valid secret key.
                              type: string
                            name:
                              default: ''
                              description: |-
                                Name of the referent.
                                This field is effectively required, but due to backwards compatibility is
                                allowed to be empty. Instances of this type with an empty value here are
                                almost certainly wrong.
                                More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
                              type: string
                            optional:
                              description: Specify whether the Secret or its key must be defined
                              type: boolean
                          required:
                          - key
                          type: object
                          x-kubernetes-map-type: atomic
                      type: object
                  required:
                  - name
                  type: object
                type: array
              expireTime:
                description: |-
                  ExpireTime specifies when this sandbox should expire and be garbage collected.
                  If not set, the sandbox will not expire automatically.
                format: date-time
                type: string
              failurePolicy:
                default: Manual
                description: |-
                  FailurePolicy defines the recovery strategy when the fastlet is lost.
                  Defaults to "Manual".
                enum:
                - Manual
                - AutoRecreate
                type: string
              image:
                minLength: 1
                type: string
              poolRef:
                description: |-
                  PoolRef specifies which SandboxPool this sandbox should be scheduled to.
                  This field is required.
                minLength: 1
                type: string
              recoveryTimeoutSeconds:
                default: 60
                description: |-
                  RecoveryTimeoutSeconds is the duration to wait before taking action after losing contact with fastlet.
                  Defaults to 60 seconds.
                format: int32
                type: integer
              resetRevision:
                description: |-
                  ResetRevision is an opaque token (usually a timestamp) used to trigger a manual reset.
                  When Spec.ResetRevision > Status.Runtime.AcceptedResetRevision, the sandbox will be rescheduled.
                format: date-time
                type: string
              state:
                default: Running
                description: |-
                  State is the desired runtime lifecycle. Running (the default) keeps a
                  live runtime; Paused checkpoints the runtime to the artifact store
                  and releases it. Pausing requires a Ready runtime; flipping back to
                  Running resumes the recorded checkpoint, possibly on a different
                  Fastlet.
                enum:
                - Running
                - Paused
                type: string
              workingDir:
                type: string
            required:
            - image
            - poolRef
            type: object
          status:
            description: SandboxStatus defines the observed state of Sandbox.
            properties:
              actionBindings:
                items:
                  properties:
                    handler:
                      type: string
                    lastTransitionTime:
                      format: date-time
                      type: string
                    message:
                      type: string
                    state:
                      description: ActionState is the observed lifecycle of one Action Binding.
                      enum:
                      - Pending
                      - Applying
                      - Ready
                      - Failed
                      type: string
                  required:
                  - handler
                  - state
                  type: object
                type: array
                x-kubernetes-list-type: atomic
              conditions:
                items:
                  description: Condition contains details for one aspect of the current state of this API Resource.
                  properties:
                    lastTransitionTime:
                      description: |-
                        lastTransitionTime is the last time the condition transitioned from one status to another.
                        This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.
                      format: date-time
                      type: string
                    message:
                      description: |-
                        message is a human readable message indicating details about the transition.
                        This may be an empty string.
                      maxLength: 32768
                      type: string
                    observedGeneration:
                      description: |-
                        observedGeneration represents the .metadata.generation that the condition was set based upon.
                        For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date
                        with respect to the current state of the instance.
                      format: int64
                      minimum: 0
                      type: integer
                    reason:
                      description: |-
                        reason contains a programmatic identifier indicating the reason for the condition's last transition.
                        Producers of specific condition types may define expected values and meanings for this field,
                        and whether the values are considered a guaranteed API.
                        The value should be a CamelCase string.
                        This field may not be empty.
                      maxLength: 1024
                      minLength: 1
                      pattern: ^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_])?$
                      type: string
                    status:
                      description: status of the condition, one of True, False, Unknown.
                      enum:
                      - 'True'
                      - 'False'
                      - Unknown
                      type: string
                    type:
                      description: type of condition in CamelCase or in foo.example.com/CamelCase.
                      maxLength: 316
                      pattern: ^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$
                      type: string
                  required:
                  - lastTransitionTime
                  - message
                  - reason
                  - status
                  - type
                  type: object
                type: array
                x-kubernetes-list-map-keys:
                - type
                x-kubernetes-list-type: map
              dataPlane:
                properties:
                  lastTransitionTime:
                    format: date-time
                    type: string
                  message:
                    type: string
                  routeGeneration:
                    format: int64
                    type: integer
                  state:
                    description: DataPlaneState is the lifecycle of the Sandbox interaction route.
                    enum:
                    - Unknown
                    - Pending
                    - Publishing
                    - Ready
                    - Draining
                    - Failed
                    - Unavailable
                    type: string
                type: object
              infraComponents:
                items:
                  properties:
                    lastTransitionTime:
                      format: date-time
                      type: string
                    message:
                      type: string
                    name:
                      type: string
                    state:
                      description: InfraComponentState is the lifecycle of one named local component route.
                      enum:
                      - Starting
                      - Ready
                      - Failed
                      type: string
                  required:
                  - name
                  - state
                  type: object
                type: array
                x-kubernetes-list-map-keys:
                - name
                x-kubernetes-list-type: map
              observedGeneration:
                format: int64
                type: integer
              placement:
                properties:
                  attempt:
                    format: int64
                    type: integer
                  fastletName:
                    type: string
                  fastletPodUID:
                    description: |-
                      UID is a type that holds unique ID values, including UUIDs.  Because we
                      don't ONLY use UUIDs, this is an alias to string.  Being a type captures
                      intent and helps make sure that UIDs and names do not get conflated.
                    type: string
                  recovery:
                    properties:
                      deadline:
                        format: date-time
                        type: string
                      detectedAt:
                        format: date-time
                        type: string
                    required:
                    - deadline
                    - detectedAt
                    type: object
                type: object
              runtime:
                properties:
                  acceptedResetRevision:
                    format: date-time
                    type: string
                  checkpoint:
                    description: |-
                      Checkpoint is the artifact-store checkpoint a Paused Sandbox resumes
                      from. It is authoritative only while State is Pausing, Paused, or
                      Resuming (see CheckpointActive); in any other state it must be read
                      as "no checkpoint" and is cleared by the controller. A Paused
                      Sandbox without a checkpoint cannot be resumed and must be reset.
                    properties:
                      artifactDigest:
                        description: |-
                          ArtifactDigest is the sha256 of the manifest document. It addresses
                          the artifact set independently of ManifestRef.
                        type: string
                      checkpointID:
                        description: |-
                          CheckpointID is the Fastlet-side task identity that produced the
                          checkpoint, derived from the Sandbox UID, the spec generation that
                          requested the pause, and the pause attempt epoch.
                        type: string
                      fastletName:
                        description: |-
                          FastletName/FastletPodUID locate the Fastlet that captured the
                          checkpoint. Diagnostics only: the Fastlet may already be gone and is
                          never the resume target contract.
                        type: string
                      fastletPodUID:
                        description: |-
                          UID is a type that holds unique ID values, including UUIDs.  Because we
                          don't ONLY use UUIDs, this is an alias to string.  Being a type captures
                          intent and helps make sure that UIDs and names do not get conflated.
                        type: string
                      manifestRef:
                        description: |-
                          ManifestRef is the s3:// URI of the checkpoint manifest, published in
                          the standard artifact-set layout (rootfs/vmstate/memory/SHA256SUMS).
                        type: string
                      pausedAt:
                        description: PausedAt is when the checkpoint became durable in the store.
                        format: date-time
                        type: string
                      sizeBytes:
                        description: SizeBytes is the total logical size of the published artifact set.
                        format: int64
                        type: integer
                    required:
                    - artifactDigest
                    - checkpointID
                    - manifestRef
                    type: object
                  generation:
                    format: int64
                    type: integer
                  lastTransitionTime:
                    format: date-time
                    type: string
                  message:
                    type: string
                  pauseAttempt:
                    description: |-
                      PauseAttempt is the retry epoch of the pause FSM. The controller
                      increments it before triggering a new checkpoint attempt (after a
                      transient failure) and derives the Fastlet checkpoint task identity
                      from it, so retrying a lost outcome replays the same task while a new
                      attempt never reuses a terminated task id. Reset clears it.
                    format: int64
                    type: integer
                  state:
                    description: RuntimeState is the lifecycle of the concrete Sandbox runtime.
                    enum:
                    - Unknown
                    - Pending
                    - Creating
                    - Ready
                    - Pausing
                    - Paused
                    - Resuming
                    - Stopping
                    - Stopped
                    - Failed
                    - Unavailable
                    type: string
                type: object
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.20.1
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: sandboxsnapshots.sandbox.fast.io
spec:
  group: sandbox.fast.io
  names:
    kind: SandboxSnapshot
    listKind: SandboxSnapshotList
    plural: sandboxsnapshots
    singular: sandboxsnapshot
  scope: Namespaced
  versions:
  - name: v1alpha2
    schema:
      openAPIV3Schema:
        description: |-
          SandboxSnapshot is a one-shot snapshot of a running Sandbox: the artifacts
          (rootfs, vmstate, memory) are published to the artifact store in the
          SandboxTemplate layout, addressable under spec.templateName. The object is
          created by fastpath (CreateSandboxSnapshot) and driven to completion by
          the controller; a Sandbox (or template name) with a non-terminal snapshot
          rejects further snapshot requests.
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: |-
              SandboxSnapshotSpec defines the desired snapshot. The spec is immutable
              by convention: a snapshot is one-shot and re-snapshotting requires a new
              object. These CRDs ship without CEL (x-kubernetes-validations) for legacy
              (< 1.25) API servers, so the API server will accept spec edits; do not
              rely on API-level rejection.
            properties:
              sandboxRef:
                description: |-
                  SandboxRef is the running Sandbox to snapshot. The Sandbox must be
                  Ready and assigned when the snapshot is triggered.
                properties:
                  name:
                    maxLength: 253
                    minLength: 1
                    type: string
                  namespace:
                    maxLength: 63
                    minLength: 1
                    type: string
                  uid:
                    description: |-
                      UID fences the reference against a Sandbox recreated under the same
                      name. Empty accepts the current Sandbox; fastpath fills it from the
                      live object it validated.
                    type: string
                required:
                - name
                - namespace
                type: object
              templateName:
                description: |-
                  TemplateName is the artifact-store index key the artifact set is
                  published under: publish writes index/<sha256(templateName)>.json, and
                  a later Sandbox create with image=TemplateName boots from the
                  snapshot through the standard pull/restore chain. Unlike a
                  SandboxTemplate build, no default sha256(image) index is written.
                  The index key is global across namespaces: two concurrently running
                  snapshots with the same TemplateName overwrite each other's artifacts
                  (last writer wins), and FastPath's pre-check therefore rejects a
                  non-terminal holder of a name cluster-wide.
                maxLength: 255
                pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*(/[a-zA-Z0-9._-]+)*(:[a-zA-Z0-9._-]{1,127})?$
                type: string
            required:
            - sandboxRef
            - templateName
            type: object
          status:
            description: |-
              SandboxSnapshotStatus reports the observed state of one snapshot attempt.
              All fields are projections written by the control plane; the artifact
              facts come from the fastlet that executed the snapshot.
            properties:
              artifactDigest:
                description: ArtifactDigest is the sha256 of the published manifest document.
                type: string
              completedAt:
                description: CompletedAt is when the snapshot reached a terminal phase.
                format: date-time
                type: string
              conditions:
                items:
                  description: Condition contains details for one aspect of the current state of this API Resource.
                  properties:
                    lastTransitionTime:
                      description: |-
                        lastTransitionTime is the last time the condition transitioned from one status to another.
                        This should be when the underlying condition changed.  If that is not known, then using the time when the API field changed is acceptable.
                      format: date-time
                      type: string
                    message:
                      description: |-
                        message is a human readable message indicating details about the transition.
                        This may be an empty string.
                      maxLength: 32768
                      type: string
                    observedGeneration:
                      description: |-
                        observedGeneration represents the .metadata.generation that the condition was set based upon.
                        For instance, if .metadata.generation is currently 12, but the .status.conditions[x].observedGeneration is 9, the condition is out of date
                        with respect to the current state of the instance.
                      format: int64
                      minimum: 0
                      type: integer
                    reason:
                      description: |-
                        reason contains a programmatic identifier indicating the reason for the condition's last transition.
                        Producers of specific condition types may define expected values and meanings for this field,
                        and whether the values are considered a guaranteed API.
                        The value should be a CamelCase string.
                        This field may not be empty.
                      maxLength: 1024
                      minLength: 1
                      pattern: ^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_])?$
                      type: string
                    status:
                      description: status of the condition, one of True, False, Unknown.
                      enum:
                      - 'True'
                      - 'False'
                      - Unknown
                      type: string
                    type:
                      description: type of condition in CamelCase or in foo.example.com/CamelCase.
                      maxLength: 316
                      pattern: ^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$
                      type: string
                  required:
                  - lastTransitionTime
                  - message
                  - reason
                  - status
                  - type
                  type: object
                type: array
                x-kubernetes-list-map-keys:
                - type
                x-kubernetes-list-type: map
              fastletName:
                description: |-
                  FastletName/FastletPodUID locate the fastlet the snapshot was
                  triggered on, resolved from the target Sandbox's assignment at
                  trigger time. The assignment annotation stays authoritative; these
                  fields are a projection.
                type: string
              fastletPodUID:
                description: |-
                  UID is a type that holds unique ID values, including UUIDs.  Because we
                  don't ONLY use UUIDs, this is an alias to string.  Being a type captures
                  intent and helps make sure that UIDs and names do not get conflated.
                type: string
              manifestRef:
                description: |-
                  ManifestRef is the s3:// URI of the published manifest.json
                  (Succeeded only).
                type: string
              message:
                description: Message is the latest progress or failure reason.
                type: string
              observedGeneration:
                format: int64
                type: integer
              phase:
                description: Phase is the snapshot lifecycle.
                enum:
                - Pending
                - Creating
                - Publishing
                - Succeeded
                - Failed
                type: string
              sandboxUID:
                description: SandboxUID is the UID of the snapshotted Sandbox incarnation.
                type: string
              sizeBytes:
                description: SizeBytes is the total logical size of the published artifact set.
                format: int64
                type: integer
              snapshotID:
                description: SnapshotID is the fastlet-side identity of the snapshot task.
                type: string
              startedAt:
                description: StartedAt is when the fastlet accepted the snapshot.
                format: date-time
                type: string
              triggered:
                description: |-
                  Triggered pins the full trigger-time placement (fastlet plus the
                  Sandbox identity fence) once the snapshot is accepted. Observations
                  resolve against it, not the Sandbox's live assignment. Residual
                  window: if the fastlet crashes exactly during the final index upload,
                  the object can be terminal Failed with the index still landed
                  (last-writer-wins for the template name); every other failure path
                  publishes nothing.
                properties:
                  assignmentAttempt:
                    format: int64
                    type: integer
                  fastletName:
                    description: FastletName/FastletPodUID identify the fastlet that accepted the task.
                    type: string
                  fastletPodUid:
                    type: string
                  instanceGeneration:
                    format: int64
                    type: integer
                  runtimeInstanceId:
                    description: |-
                      RuntimeInstanceID/InstanceGeneration/AssignmentAttempt are the Sandbox
                      identity fence captured at trigger time; observations replay them so
                      the fastlet-side claim check matches exactly.
                    type: string
                type: object
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  annotations:
    controller-gen.kubebuilder.io/version: v0.20.1
    helm.sh/resource-policy: keep
  labels:
    app.kubernetes.io/instance: bakery-opensandbox
    app.kubernetes.io/name: base
    app.kubernetes.io/part-of: opensandbox
    helm.sh/chart: base-1.1.1
  name: sandboxtemplates.sandbox.fast.io
spec:
  group: sandbox.fast.io
  names:
    kind: SandboxTemplate
    listKind: SandboxTemplateList
    plural: sandboxtemplates
    singular: sandboxtemplate
  scope: Namespaced
  versions:
  - name: v1alpha2
    schema:
      openAPIV3Schema:
        description: |-
          SandboxTemplate is a declarative golden-image build (OSEP-0023 design,
          fast-sandbox flavor): an OCI source image, runtime injection, guest init,
          readiness, and output artifacts. The build is executed by a controller
          (Phase 2) or locally by the CLI (Phase 1).
        properties:
          apiVersion:
            description: |-
              APIVersion defines the versioned schema of this representation of an object.
              Servers should convert recognized schemas to the latest internal value, and
              may reject unrecognized values.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
            type: string
          kind:
            description: |-
              Kind is a string value representing the REST resource this object represents.
              Servers may infer this from the endpoint the client submits requests to.
              Cannot be updated.
              In CamelCase.
              More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
            type: string
          metadata:
            type: object
          spec:
            description: SandboxTemplateSpec defines the desired golden-image build.
            properties:
              entrypoint:
                description: |-
                  Entrypoint is the guest business command as an argv list; empty
                  defaults to ["tail","-f","/dev/null"].
                items:
                  type: string
                type: array
              envs:
                description: |-
                  Envs is injected as /etc/sandbox-init.env in the guest (literal
                  values only; valueFrom is not supported). The source image's own
                  OCI Config.Env (the merged Dockerfile ENV) is inherited like a
                  container runtime would; an env with the same name here overrides
                  the inherited value.
                items:
                  description: EnvVar represents an environment variable present in a Container.
                  properties:
                    name:
                      description: |-
                        Name of the environment variable.
                        May consist of any printable ASCII characters except '='.
                      type: string
                    value:
                      description: |-
                        Variable references $(VAR_NAME) are expanded
                        using the previously defined environment variables in the container and
                        any service environment variables. If a variable cannot be resolved,
                        the reference in the input string will be unchanged. Double $$ are reduced
                        to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e.
                        "$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)".
                        Escaped references will never be expanded, regardless of whether the variable
                        exists or not.
                        Defaults to "".
                      type: string
                    valueFrom:
                      description: Source for the environment variable's value. Cannot be used if value is not empty.
                      properties:
                        configMapKeyRef:
                          description: Selects a key of a ConfigMap.
                          properties:
                            key:
                              description: The key to select.
                              type: string
                            name:
                              default: ''
                              description: |-
                                Name of the referent.
                                This field is effectively required, but due to backwards compatibility is
                                allowed to be empty. Instances of this type with an empty value here are
                                almost certainly wrong.
                                More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
                              type: string
                            optional:
                              description: Specify whether the ConfigMap or its key must be defined
                              type: boolean
                          required:
                          - key
                          type: object
                          x-kubernetes-map-type: atomic
                        fieldRef:
                          description: |-
                            Selects a field of the pod: supports metadata.name, metadata.namespace, `metadata.labels['<KEY>']`, `metadata.annotations['<KEY>']`,
                            spec.nodeName, spec.serviceAccountName, status.hostIP, status.podIP, status.podIPs.
                          properties:
                            apiVersion:
                              description: Version of the schema the FieldPath is written in terms of, defaults
                                to "v1".
                              type: string
                            fieldPath:
                              description: Path of the field to select in the specified API version.
                              type: string
                          required:
                          - fieldPath
                          type: object
                          x-kubernetes-map-type: atomic
                        fileKeyRef:
                          description: |-
                            FileKeyRef selects a key of the env file.
                            Requires the EnvFiles feature gate to be enabled.
                          properties:
                            key:
                              description: |-
                                The key within the env file. An invalid key will prevent the pod from starting.
                                The keys defined within a source may consist of any printable ASCII characters except '='.
                                During Alpha stage of the EnvFiles feature gate, the key size is limited to 128 characters.
                              type: string
                            optional:
                              default: false
                              description: |-
                                Specify whether the file or its key must be defined. If the file or key
                                does not exist, then the env var is not published.
                                If optional is set to true and the specified key does not exist,
                                the environment variable will not be set in the Pod's containers.

                                If optional is set to false and the specified key does not exist,
                                an error will be returned during Pod creation.
                              type: boolean
                            path:
                              description: |-
                                The path within the volume from which to select the file.
                                Must be relative and may not contain the '..' path or start with '..'.
                              type: string
                            volumeName:
                              description: The name of the volume mount containing the env file.
                              type: string
                          required:
                          - key
                          - path
                          - volumeName
                          type: object
                          x-kubernetes-map-type: atomic
                        resourceFieldRef:
                          description: |-
                            Selects a resource of the container: only resources limits and requests
                            (limits.cpu, limits.memory, limits.ephemeral-storage, requests.cpu, requests.memory and requests.ephemeral-storage) are currently supported.
                          properties:
                            containerName:
                              description: 'Container name: required for volumes, optional for env vars'
                              type: string
                            divisor:
                              anyOf:
                              - type: integer
                              - type: string
                              description: Specifies the output format of the exposed resources, defaults to "1"
                              pattern: ^(\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))(([KMGTPE]i)|[numkMGTPE]|([eE](\+|-)?(([0-9]+(\.[0-9]*)?)|(\.[0-9]+))))?$
                              x-kubernetes-int-or-string: true
                            resource:
                              description: 'Required: resource to select'
                              type: string
                          required:
                          - resource
                          type: object
                          x-kubernetes-map-type: atomic
                        secretKeyRef:
                          description: Selects a key of a secret in the pod's namespace
                          properties:
                            key:
                              description: The key of the secret to select from.  Must be a valid secret key.
                              type: string
                            name:
                              default: ''
                              description: |-
                                Name of the referent.
                                This field is effectively required, but due to backwards compatibility is
                                allowed to be empty. Instances of this type with an empty value here are
                                almost certainly wrong.
                                More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
                              type: string
                            optional:
                              description: Specify whether the Secret or its key must be defined
                              type: boolean
                          required:
                          - key
                          type: object
                          x-kubernetes-map-type: atomic
                      type: object
                  required:
                  - name
                  type: object
                type: array
              execd:
                description: Execd is the OpenSandbox execd image whose runtime files are injected.
                type: string
              image:
                description: Image is the OCI image reference to convert.
                type: string
              indexKey:
                description: "IndexKey optionally names an additional content-addressed image-index\nkey the publish\
                  \ stage writes alongside the default sha256(image) key.\nUse case: per-template artifact identity\
                  \ \u2014 the OpenSandbox server sets\nit to the template ID so two templates of the same source\
                  \ image never\nalias each other's artifact sets or node caches. The index payload's\nimage field\
                  \ equals the key it is written under, so pull-side byte\nmatching works unchanged. The default\
                  \ key stays last-writer-wins for\nwarmImages and older clients."
                maxLength: 255
                pattern: ^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*(/[a-zA-Z0-9._-]+)*(:[a-zA-Z0-9._-]{1,127})?$
                type: string
              init:
                description: |-
                  Init is the injected PID 1 path inside the rootfs. The init script
                  carries the readiness marker and heartbeat the build depends on, so it
                  is always injected: empty defaults to /usr/local/sbin/sandbox-init.
                type: string
              kernel:
                description: |-
                  Kernel is the guest kernel to embed; it must be present in the builder
                  image under this name (the builder image embeds one kernel at build
                  time via the KERNEL_NAME build arg).
                type: string
              machine:
                description: Machine describes the reference machine of the golden image.
                properties:
                  memory:
                    default: 2Gi
                    type: string
                  vcpu:
                    default: '1'
                    type: string
                required:
                - memory
                - vcpu
                type: object
              output:
                description: Output describes the artifacts to produce and where to publish them.
                properties:
                  format:
                    default: overlaybd
                    description: Format selects the storage encoding of the snapshot set.
                    enum:
                    - native
                    - overlaybd
                    type: string
                  prime:
                    description: "Prime optionally selects seed nodes (by label selector) whose agent\nwarms the\
                      \ local cache after a successful build.\nNot yet implemented: reserved \u2014 the controller\
                      \ currently ignores it."
                    properties:
                      nodeSelector:
                        additionalProperties:
                          type: string
                        minProperties: 1
                        type: object
                    required:
                    - nodeSelector
                    type: object
                  publish:
                    description: |-
                      Publish is the S3-compatible object store target, e.g.
                      s3://bucket/sandbox-images/ (digest-addressed publication). When
                      empty, the controller defaults it to the platform artifact store
                      (the fast-sandbox-artifact-store ConfigMap); when set it must equal
                      that store, so a template cannot silently drift away from the store
                      the node agents read. Without either, the build fails with an
                      invalid-output condition (durable artifacts have no destination).
                    type: string
                  publishSecretRef:
                    description: |-
                      PublishSecretRef references (imagePullSecrets-style) the secret holding
                      the object-store credentials. The secret MUST live in the template's
                      namespace, where the build Pod runs (a Pod can only mount Secrets from
                      its own namespace). It is created and maintained out of band by the
                      platform operator; the template only names it. Expected keys:
                      accessKeyId, secretAccessKey, endpoint, region (all required when the
                      reference is set). The controller mounts the Secret into the build Pod
                      and the builder reads the keys as files; secret contents are never
                      copied into the CR status, the Pod env, or the artifact manifest.
                    properties:
                      name:
                        default: ''
                        description: |-
                          Name of the referent.
                          This field is effectively required, but due to backwards compatibility is
                          allowed to be empty. Instances of this type with an empty value here are
                          almost certainly wrong.
                          More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names
                        type: string
                    type: object
                    x-kubernetes-map-type: atomic
                  rootfsSize:
                    default: 30Gi
                    description: "RootfsSize is the logical size of the converted rootfs.ext4 \u2014 the\ncapacity\
                      \ the guest sees as its root drive. A Kubernetes resource\nquantity; the file is sparse. It\
                      \ must be large enough to hold the\nexpanded OCI image content."
                    type: string
                required:
                - format
                - rootfsSize
                type: object
              readiness:
                description: Readiness defines when the guest is considered ready.
                properties:
                  healthCheck:
                    description: |-
                      HealthCheck is polled as the fallback; empty uses the source image
                      CMD-SHELL.
                    type: string
                  probe:
                    description: 'Probe is checked first: tcp://host:port or cmd://<command>.'
                    type: string
                  warmupSeconds:
                    default: 60
                    format: int32
                    minimum: 0
                    type: integer
                required:
                - warmupSeconds
                type: object
            required:
            - image
            - kernel
            - machine
            - output
            - readiness
            type: object
          status:
            description: SandboxTemplateStatus reports the latest build outcome.
            properties:
              artifactDigest:
                description: ArtifactDigest is the sha256 of the manifest document itself.
                type: string
              conditions:
                description: Conditions detail progress.
                items:
                  description: SandboxTemplateCondition represents one condition of a SandboxTemplate.
                  properties:
                    lastTransitionTime:
                      description: LastTransitionTime is the last time the condition transitioned.
                      format: date-time
                      type: string
                    message:
                      description: Message is a human-readable message about the condition.
                      type: string
                    reason:
                      description: Reason is a brief reason for the condition.
                      type: string
                    status:
                      description: Status is the condition status (True/False).
                      enum:
                      - 'True'
                      - 'False'
                      type: string
                    type:
                      description: Type is the condition type.
                      enum:
                      - BuildSucceeded
                      type: string
                  required:
                  - status
                  - type
                  type: object
                type: array
              lastBuildTime:
                description: LastBuildTime is when the last build completed.
                format: date-time
                type: string
              manifestRef:
                description: ManifestRef points at the published manifest in the object store.
                type: string
              observedGeneration:
                description: ObservedGeneration is the generation of the last applied build.
                format: int64
                type: integer
              phase:
                description: Phase is the overall build phase.
                enum:
                - Pending
                - Building
                - Succeeded
                - Failed
                type: string
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
---
apiVersion: v1
kind: Namespace
metadata:
  name: opensandbox-system
  annotations: {}
  labels:
    app.kubernetes.io/part-of: bakery-sandboxes
---
apiVersion: v1
kind: Namespace
metadata:
  name: bakery-sandboxes
  annotations: {}
  labels:
    app.kubernetes.io/part-of: bakery-sandboxes
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sandbox-network-boundary
  namespace: bakery-sandboxes
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: opensandbox-system
      podSelector:
        matchLabels:
          app.kubernetes.io/name: opensandbox-server
    ports:
    - protocol: TCP
      port: 44772
    - protocol: TCP
      port: 18080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
        - 169.254.0.0/16
        - 192.0.2.11/32
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: opensandbox-server-ingress
  namespace: opensandbox-system
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: opensandbox-server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ui-bakery
      podSelector:
        matchLabels:
          app: ui-bakery-sandbox-api
    ports:
    - protocol: TCP
      port: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: opensandbox-control-plane-egress
  namespace: opensandbox-system
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - ipBlock:
        cidr: 192.0.2.10/32
    - ipBlock:
        cidr: 192.0.2.11/32
    ports:
    - protocol: TCP
      port: 443
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: bakery-sandboxes
    ports:
    - protocol: TCP
      port: 44772
    - protocol: TCP
      port: 18080
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: sandbox-capacity
  namespace: bakery-sandboxes
spec:
  hard:
    count/batchsandboxes.sandbox.opensandbox.io: '3'
    limits.cpu: '4'
    limits.ephemeral-storage: 12Gi
    limits.memory: 6Gi
    pods: '6'
    requests.cpu: '4'
    requests.ephemeral-storage: 12Gi
    requests.memory: 6Gi
    persistentvolumeclaims: '0'
    services.loadbalancers: '0'
    services.nodeports: '0'
---
apiVersion: v1
kind: LimitRange
metadata:
  name: sandbox-container-defaults
  namespace: bakery-sandboxes
spec:
  limits:
  - type: Container
    defaultRequest:
      ephemeral-storage: 512Mi
    default:
      ephemeral-storage: 2Gi
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: opensandbox-controller-manager
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-controller-1.1.1
    app.kubernetes.io/name: opensandbox
    app.kubernetes.io/instance: bakery-opensandbox-controller
    control-plane: controller-manager
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: serviceaccount
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: opensandbox-server
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-server-1.1.1
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: opensandbox-server
    app.kubernetes.io/part-of: opensandbox
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  labels:
    helm.sh/chart: opensandbox-controller-1.1.1
    app.kubernetes.io/name: opensandbox
    app.kubernetes.io/instance: bakery-opensandbox-controller
    control-plane: controller-manager
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: controller-manager
data:
  pod-recovery-stuck-threshold: 1m
  pod-recovery-max-attempts: '3'
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: opensandbox-server-config
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-server-1.1.1
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: opensandbox-server
    app.kubernetes.io/part-of: opensandbox
data:
  config.toml: |
    [server]
    host = "0.0.0.0"
    port = 8080
    max_sandbox_timeout_seconds = 86400

    [proxy]
    resolve_internal = true

    [runtime]
    type = "kubernetes"
    execd_image = "opensandbox/execd:v1.1.0"

    [store]
    type = "sqlite"
    path = "/var/lib/opensandbox/opensandbox.db"

    [kubernetes]
    kubeconfig_path = ""
    namespace = "bakery-sandboxes"
    workload_provider = "batchsandbox"
    image_pull_policy = "IfNotPresent"
    batchsandbox_template_file = "/etc/opensandbox/bakery-template.yaml"
    sandbox_create_timeout_seconds = 180

    [kubernetes.execd_init_resources]
    requests = { cpu = "50m", memory = "64Mi" }
    limits = { cpu = "250m", memory = "128Mi" }

    [egress]
    image = "opensandbox/egress:v1.1.7"
    mode = "dns+nft"
    requests = { cpu = "25m", memory = "32Mi" }
    limits = { cpu = "250m", memory = "256Mi" }


    [ingress]
    mode = "direct"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bakery-opensandbox-workload
  namespace: opensandbox-system
data:
  batchsandbox-template.yaml: |
    spec:
      replicas: 1
      template:
        spec:
          restartPolicy: Never
          automountServiceAccountToken: false
          enableServiceLinks: false
          securityContext:
            seccompProfile:
              type: RuntimeDefault
          containers:
          - name: sandbox
            securityContext:
              runAsUser: 1001
              runAsGroup: 1001
              runAsNonRoot: true
              allowPrivilegeEscalation: false
              privileged: false
              capabilities:
                drop:
                - ALL
          imagePullSecrets:
          - name: uibakery-registry
          nodeSelector:
            kubernetes.io/os: linux
            kubernetes.io/arch: amd64
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: opensandbox-state
  namespace: opensandbox-system
  annotations:
    helm.sh/resource-policy: keep
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: opensandbox-server-role
  labels:
    helm.sh/chart: opensandbox-server-1.1.1
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: opensandbox-server
    app.kubernetes.io/part-of: opensandbox
rules:
- apiGroups:
  - ''
  resources:
  - pods
  - pods/status
  - pods/log
  - events
  - services
  - configmaps
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ''
  resources:
  - namespaces
  verbs:
  - get
  - list
- apiGroups:
  - ''
  resources:
  - secrets
  verbs:
  - create
  - delete
  - get
- apiGroups:
  - ''
  resources:
  - persistentvolumeclaims
  verbs:
  - create
  - delete
  - get
  - list
  - patch
- apiGroups:
  - node.k8s.io
  resources:
  - runtimeclasses
  verbs:
  - get
  - list
- apiGroups:
  - sandbox.opensandbox.io
  resources:
  - batchsandboxes
  - batchsandboxes/status
  - batchsandboxes/finalizers
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - sandbox.opensandbox.io
  resources:
  - pools
  - pools/status
  - pools/finalizers
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - sandbox.opensandbox.io
  resources:
  - sandboxsnapshots
  - sandboxsnapshots/status
  - sandboxsnapshots/finalizers
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - sandbox.fast.io
  resources:
  - sandboxes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - sandbox.fast.io
  resources:
  - sandboxtemplates
  verbs:
  - create
  - delete
  - get
  - list
  - watch
- apiGroups:
  - sandbox.fast.io
  resources:
  - sandboxsnapshots
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: opensandbox-manager-role
rules:
- apiGroups:
  - ''
  resources:
  - pods
  - pods/status
  - configmaps
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - jobs/status
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - sandbox.opensandbox.io
  resources:
  - batchsandboxes
  - pools
  - sandboxsnapshots
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: opensandbox-manager-role
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: opensandbox-manager-role
subjects:
- kind: ServiceAccount
  name: opensandbox-controller-manager
  namespace: opensandbox-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: opensandbox-leader-election-role
  namespace: opensandbox-system
rules:
- apiGroups:
  - ''
  resources:
  - configmaps
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
- apiGroups:
  - ''
  resources:
  - events
  verbs:
  - create
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: opensandbox-controller-workloads
  namespace: bakery-sandboxes
rules:
- apiGroups:
  - ''
  resources:
  - pods
  - pods/status
  - events
  verbs:
  - get
  - list
  - watch
  - create
  - delete
  - patch
  - update
- apiGroups:
  - batch
  resources:
  - jobs
  - jobs/status
  verbs:
  - get
  - list
  - watch
  - create
  - delete
  - patch
  - update
- apiGroups:
  - sandbox.opensandbox.io
  resources:
  - batchsandboxes
  - batchsandboxes/status
  - batchsandboxes/finalizers
  - pools
  - pools/status
  - pools/finalizers
  - sandboxsnapshots
  - sandboxsnapshots/status
  - sandboxsnapshots/finalizers
  verbs:
  - get
  - list
  - watch
  - create
  - delete
  - patch
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: opensandbox-leader-election-role
  namespace: opensandbox-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: opensandbox-leader-election-role
subjects:
- kind: ServiceAccount
  name: opensandbox-controller-manager
  namespace: opensandbox-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: opensandbox-controller-workloads
  namespace: bakery-sandboxes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: opensandbox-controller-workloads
subjects:
- kind: ServiceAccount
  name: opensandbox-controller-manager
  namespace: opensandbox-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: opensandbox-server-workloads
  namespace: bakery-sandboxes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: opensandbox-server-role
subjects:
- kind: ServiceAccount
  name: opensandbox-server
  namespace: opensandbox-system
---
apiVersion: v1
kind: Service
metadata:
  name: opensandbox-server
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-server-1.1.1
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: opensandbox-server
    app.kubernetes.io/part-of: opensandbox
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensandbox-controller-manager
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-controller-1.1.1
    app.kubernetes.io/name: opensandbox
    app.kubernetes.io/instance: bakery-opensandbox-controller
    control-plane: controller-manager
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: controller-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: opensandbox
      app.kubernetes.io/instance: bakery-opensandbox-controller
      control-plane: controller-manager
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/default-container: manager
      labels:
        app.kubernetes.io/name: opensandbox
        app.kubernetes.io/instance: bakery-opensandbox-controller
        control-plane: controller-manager
    spec:
      serviceAccountName: opensandbox-controller-manager
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: manager
        image: opensandbox/controller:release-1.1.1
        imagePullPolicy: IfNotPresent
        command:
        - /workspace/server
        args:
        - --leader-elect
        - --health-probe-bind-address=:8081
        - --zap-log-level=info
        - --kube-client-qps=100
        - --kube-client-burst=200
        - --image-committer-image=sandbox-registry.cn-zhangjiakou.cr.aliyuncs.com/opensandbox/image-committer:release-1.1.1
        - --commit-job-timeout=10m
        ports:
        - name: health
          containerPort: 8081
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: false
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8081
          initialDelaySeconds: 15
          periodSeconds: 20
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /readyz
            port: 8081
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 50m
            memory: 128Mi
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      terminationGracePeriodSeconds: 10
      imagePullSecrets:
      - name: uibakery-registry
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opensandbox-server
  namespace: opensandbox-system
  labels:
    helm.sh/chart: opensandbox-server-1.1.1
    app.kubernetes.io/name: opensandbox-server
    app.kubernetes.io/instance: bakery-opensandbox-server
    app.kubernetes.io/version: 1.1.1
    app.kubernetes.io/component: opensandbox-server
    app.kubernetes.io/part-of: opensandbox
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app.kubernetes.io/name: opensandbox-server
      app.kubernetes.io/instance: bakery-opensandbox-server
  template:
    metadata:
      labels:
        app.kubernetes.io/name: opensandbox-server
        app.kubernetes.io/instance: bakery-opensandbox-server
        app.kubernetes.io/part-of: opensandbox
      annotations: {}
    spec:
      serviceAccountName: opensandbox-server
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        runAsUser: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: main
        image: REPLACE_WITH_BAKERY_OPENSANDBOX_SERVER_IMAGE
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
        imagePullPolicy: IfNotPresent
        args:
        - --config
        - /etc/opensandbox/config.toml
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        env:
        - name: SANDBOX_CONFIG_PATH
          value: /etc/opensandbox/config.toml
        - name: OPENSANDBOX_SERVER_API_KEY
          valueFrom:
            secretKeyRef:
              key: api-key
              name: opensandbox-provider
        volumeMounts:
        - name: config
          mountPath: /etc/opensandbox/config.toml
          subPath: config.toml
          readOnly: true
        - mountPath: /etc/opensandbox/bakery-template.yaml
          name: workload-template
          readOnly: true
          subPath: batchsandbox-template.yaml
        - mountPath: /var/lib/opensandbox
          name: state
        - mountPath: /tmp
          name: temporary
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 10
          periodSeconds: 15
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
        resources:
          limits:
            cpu: '1'
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 256Mi
      volumes:
      - name: config
        configMap:
          name: opensandbox-server-config
      - configMap:
          name: bakery-opensandbox-workload
        name: workload-template
      - name: state
        persistentVolumeClaim:
          claimName: opensandbox-state
      - emptyDir:
          sizeLimit: 128Mi
        name: temporary
      imagePullSecrets:
      - name: uibakery-registry
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bakery-sandbox-api-config
  namespace: ui-bakery
data:
  UI_BAKERY_DOCKER_SANDBOX_PORT: '7071'
  UI_BAKERY_SANDBOX_PROVIDER: opensandbox
  UI_BAKERY_SANDBOX_PROVIDER_QUALIFIED: 'true'
  UI_BAKERY_SANDBOX_PROVIDER_ENDPOINT: http://opensandbox-server.opensandbox-system.svc:80
  UI_BAKERY_SANDBOX_INSTALLATION: bakery-byok
  UI_BAKERY_DOCKER_SANDBOX_IMAGE: cruibakeryonprem.azurecr.io/cloud/bakery-sandbox-runtime:REPLACE_WITH_BAKERY_VERSION
  UI_BAKERY_DOCKER_SANDBOX_MAX_POOL_SIZE: '1'
  UI_BAKERY_SANDBOX_BUILD_MAX_WORKLOADS: '1'
  UI_BAKERY_SANDBOX_CPU_LIMIT: '1'
  UI_BAKERY_SANDBOX_CPU_REQUEST: '0.25'
  UI_BAKERY_SANDBOX_MEMORY_LIMIT: '1073741824'
  UI_BAKERY_OPENSANDBOX_AGENT_NETWORK_POLICY: |
    {
      "defaultAction": "deny",
      "egress": [
        {
          "action": "deny",
          "target": "0.0.0.0/8"
        },
        {
          "action": "deny",
          "target": "10.0.0.0/8"
        },
        {
          "action": "deny",
          "target": "100.64.0.0/10"
        },
        {
          "action": "deny",
          "target": "127.0.0.0/8"
        },
        {
          "action": "deny",
          "target": "169.254.0.0/16"
        },
        {
          "action": "deny",
          "target": "172.16.0.0/12"
        },
        {
          "action": "deny",
          "target": "192.168.0.0/16"
        },
        {
          "action": "deny",
          "target": "224.0.0.0/4"
        },
        {
          "action": "allow",
          "target": "registry.npmjs.org"
        },
        {
          "action": "allow",
          "target": "ui.shadcn.com"

        }
      ]
    }
  UI_BAKERY_OPENSANDBOX_BUILD_NETWORK_POLICY: |
    {
      "defaultAction": "deny",
      "egress": []
    }
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sandbox-api-policy
  namespace: ui-bakery
spec:
  podSelector:
    matchLabels:
      app: ui-bakery-sandbox-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 7071
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: opensandbox-system
      podSelector:
        matchLabels:
          app.kubernetes.io/name: opensandbox-server
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: bakery-sandbox-api
  namespace: ui-bakery
spec:
  type: ClusterIP
  selector:
    app: ui-bakery-sandbox-api
  ports:
  - name: http
    port: 7071
    targetPort: http
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ui-bakery-sandbox-api
  namespace: ui-bakery
spec:
  replicas: 1
  strategy:
    type: Recreate
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: ui-bakery-sandbox-api
  template:
    metadata:
      labels:
        app: ui-bakery-sandbox-api
    spec:
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 120
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: ui-bakery-sandbox-api
        image: cruibakeryonprem.azurecr.io/cloud/bakery-sandbox-api:REPLACE_WITH_BAKERY_VERSION
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        envFrom:
        - configMapRef:
            name: bakery-sandbox-api-config
        env:
        - name: UI_BAKERY_DOCKER_SANDBOX_API_KEY
          valueFrom:
            secretKeyRef:
              name: bakery-sandbox-client
              key: api-key
        - name: UI_BAKERY_SANDBOX_PROVIDER_API_KEY
          valueFrom:
            secretKeyRef:
              name: opensandbox-provider
              key: api-key
        resources:
          limits:
            cpu: '1'
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 256Mi
        ports:
        - name: http
          containerPort: 7071
        lifecycle:
          preStop:
            exec:
              command:
              - node
              - -e
              - |
                (async () => {
                  const { setTimeout: delay } = require('node:timers/promises');
                  const deadline = performance.now() + 90000;
                  while (performance.now() < deadline) {
                    try {
                      const response = await fetch('http://127.0.0.1:7071/status', {
                        signal: AbortSignal.timeout(Math.max(1, Math.min(2000, Math.ceil(deadline - performance.now())))),
                      });
                      const status = await response.json();
                      if (response.ok && status.success === true && status.activeSandboxes === 0) return;
                    } catch {}
                    const remaining = deadline - performance.now();
                    if (remaining > 0) await delay(Math.min(1000, remaining));
                  }
                })();
        startupProbe:
          httpGet:
            path: /status
            port: http
          periodSeconds: 5
          timeoutSeconds: 20
          failureThreshold: 120
        readinessProbe:
          httpGet:
            path: /status
            port: http
          periodSeconds: 15
          timeoutSeconds: 20
        livenessProbe:
          tcpSocket:
            port: http
          periodSeconds: 30
        volumeMounts:
        - name: temporary
          mountPath: /tmp
      volumes:
      - name: temporary
        emptyDir:
          sizeLimit: 128Mi
      imagePullSecrets:
      - name: uibakery-registry
      nodeSelector:
        kubernetes.io/os: linux
        kubernetes.io/arch: amd64
```

</details>

Replace these installation-specific values in that file:

| Value | What to use |
| --- | --- |
| `REPLACE_WITH_BAKERY_VERSION` (two occurrences) | The same release version as the rest of your Bakery installation, for both API and runtime. |
| `REPLACE_WITH_BAKERY_OPENSANDBOX_SERVER_IMAGE` | Approved patched OpenSandbox provider image. |
| `192.0.2.10/32` | Kubernetes API Service IP, obtained below. |
| Every `192.0.2.11/32` occurrence | Actual control-plane endpoint IP(s). These appear in provider allow rules and workload deny boundaries. |
| `ui-bakery` | Your Bakery namespace, if different; update namespace fields and matching selectors consistently. |

```bash
KUBE_CONTEXT=YOUR_CONTEXT
kubectl --context "$KUBE_CONTEXT" -n default get service kubernetes \
  -o jsonpath='{.spec.clusterIP}{"\n"}'
```

Obtain control-plane endpoint IP(s) from the cluster administrator. DNS rules
assume CoreDNS labelled `k8s-app: kube-dns` in `kube-system`; adapt for other DNS
setups. Add non-private Pod/Service CIDRs to workload exclusions if applicable.
Set the PVC's `storageClassName` only if there is no suitable default.

Agents can reach npm and shadcn by default; builds are offline. Provider,
pool, resource and security settings are already in the manifest. Give each API
a unique, stable installation ID if multiple APIs share a provider.

For attachments, add `{"action":"allow","target":"YOUR_ATTACHMENT_STORAGE_HOST"}`
to the agent policy's `egress` array in ConfigMap `bakery-sandbox-api-config`.
Use the host from `UI_BAKERY_AZURE_CONTAINER_PREFIX`, without scheme/path; preserve
the deny rules. Private storage needs narrow exceptions in both native and CNI
policies. No extra environment variable or configuration file is needed.

## 2. Create Secrets

Run the key-generation commands **once for the initial installation**; retain the
Secrets on updates. No local key files are needed. Keep shell tracing disabled:

```bash
for namespace in opensandbox-system bakery-sandboxes; do
  kubectl --context "$KUBE_CONTEXT" create namespace "$namespace" --dry-run=client -o yaml | \
    kubectl --context "$KUBE_CONTEXT" apply -f -
done
CLIENT_KEY=$(openssl rand -hex 32)
PROVIDER_KEY=$(openssl rand -hex 32)
printf '%s' "$CLIENT_KEY" | \
  kubectl --context "$KUBE_CONTEXT" -n ui-bakery create secret generic bakery-sandbox-client \
    --from-file=api-key=/dev/stdin --dry-run=client -o yaml | \
  kubectl --context "$KUBE_CONTEXT" -n ui-bakery apply -f -
for namespace in ui-bakery opensandbox-system; do
  printf '%s' "$PROVIDER_KEY" | \
    kubectl --context "$KUBE_CONTEXT" -n "$namespace" create secret generic opensandbox-provider \
      --from-file=api-key=/dev/stdin --dry-run=client -o yaml | \
    kubectl --context "$KUBE_CONTEXT" -n "$namespace" apply -f -
done
unset CLIENT_KEY PROVIDER_KEY
```

The client key is shared by Chat/API; the provider key goes only to API/OpenSandbox.
You can use a secret manager with these same names and data keys instead.

Log into the approved private registry and copy Docker's authentication into
pull Secrets in all three namespaces. Use credentials scoped to these images;
`config.json` must contain registry auth, not only a host credential-helper setting.

```bash
docker login YOUR_PRIVATE_IMAGE_REGISTRY
# Repeat login if the approved images need another private registry.
for namespace in ui-bakery opensandbox-system bakery-sandboxes; do
  kubectl --context "$KUBE_CONTEXT" -n "$namespace" create secret generic uibakery-registry \
    --type=kubernetes.io/dockerconfigjson \
    --from-file=.dockerconfigjson="$HOME/.docker/config.json" \
    --dry-run=client -o yaml | kubectl --context "$KUBE_CONTEXT" -n "$namespace" apply -f -
done
```

## 3. Apply and connect Chat

```bash
kubectl --context "$KUBE_CONTEXT" apply --server-side -f sandboxes.yaml
kubectl --context "$KUBE_CONTEXT" wait --for=condition=Established --timeout=60s \
  crd/batchsandboxes.sandbox.opensandbox.io \
  crd/pools.sandbox.opensandbox.io \
  crd/sandboxsnapshots.sandbox.opensandbox.io \
  crd/sandboxpools.sandbox.fast.io \
  crd/sandboxes.sandbox.fast.io \
  crd/sandboxsnapshots.sandbox.fast.io \
  crd/sandboxtemplates.sandbox.fast.io
kubectl --context "$KUBE_CONTEXT" -n opensandbox-system rollout status \
  deployment/opensandbox-controller-manager --timeout=180s
kubectl --context "$KUBE_CONTEXT" -n opensandbox-system rollout status \
  deployment/opensandbox-server --timeout=180s
kubectl --context "$KUBE_CONTEXT" -n ui-bakery rollout status \
  deployment/ui-bakery-sandbox-api --timeout=180s
```

Wait for API readiness, including warm-up. On failure, check Pending Pods, image
access, storage and network policies before connecting Chat.

Add these entries to the Chat container's environment (or update their existing
ConfigMap/secret-manager source). Keep the other Chat settings:

```yaml
- name: UI_BAKERY_DOCKER_SANDBOX
  value: http://bakery-sandbox-api:7071
- name: UI_BAKERY_DOCKER_SANDBOX_API_KEY
  valueFrom:
    secretKeyRef:
      name: bakery-sandbox-client
      key: api-key
```

Apply through your normal deployment process and restart Chat after configuration
synchronizes. API and provider Services are private; no public Ingress is needed.

## 4. Check and maintain

```bash
kubectl --context "$KUBE_CONTEXT" -n ui-bakery exec deployment/ui-bakery-sandbox-api -- \
  node -e "fetch('http://127.0.0.1:7071/status').then(async r=>{console.log(await r.json());process.exit(r.ok?0:1)})"
kubectl --context "$KUBE_CONTEXT" -n bakery-sandboxes get pods
```

Ask the agent to install an npm package, build the application, and use an
attachment if configured. Completed sessions should be removed and ready stock
replenished. A full pool does not make `/status` unhealthy.

Keep one API and one provider replica; increase pool limits and matching quotas
for more parallelism. Preserve Secrets, installation ID and provider PVC. Roll
the API after its ConfigMap/Secret changes, and the provider after its configuration
changes. Provider-key rotation requires coordinated restarts. API draining waits
up to 90 seconds within a 120-second termination grace; long-running sessions are
not guaranteed to survive maintenance.

The bundled OpenSandbox CRDs originate from release 1.1.1
(commit `531700ca18a7fa5fab6a2f25d6dc68a76eddab12`) and are licensed under Apache 2.0.

<details>
<summary>OpenSandbox license</summary>

```text
Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

   1. Definitions.

      "License" shall mean the terms and conditions for use, reproduction,
      and distribution as defined by Sections 1 through 9 of this document.

      "Licensor" shall mean the copyright owner or entity authorized by
      the copyright owner that is granting the License.

      "Legal Entity" shall mean the union of the acting entity and all
      other entities that control, are controlled by, or are under common
      control with that entity. For the purposes of this definition,
      "control" means (i) the power, direct or indirect, to cause the
      direction or management of such entity, whether by contract or
      otherwise, or (ii) ownership of fifty percent (50%) or more of the
      outstanding shares, or (iii) beneficial ownership of such entity.

      "You" (or "Your") shall mean an individual or Legal Entity
      exercising permissions granted by this License.

      "Source" form shall mean the preferred form for making modifications,
      including but not limited to software source code, documentation
      source, and configuration files.

      "Object" form shall mean any form resulting from mechanical
      transformation or translation of a Source form, including but
      not limited to compiled object code, generated documentation,
      and conversions to other media types.

      "Work" shall mean the work of authorship, whether in Source or
      Object form, made available under the License, as indicated by a
      copyright notice that is included in or attached to the work
      (an example is provided in the Appendix below).

      "Derivative Works" shall mean any work, whether in Source or Object
      form, that is based on (or derived from) the Work and for which the
      editorial revisions, annotations, elaborations, or other modifications
      represent, as a whole, an original work of authorship. For the purposes
      of this License, Derivative Works shall not include works that remain
      separable from, or merely link (or bind by name) to the interfaces of,
      the Work and Derivative Works thereof.

      "Contribution" shall mean any work of authorship, including
      the original version of the Work and any modifications or additions
      to that Work or Derivative Works thereof, that is intentionally
      submitted to Licensor for inclusion in the Work by the copyright owner
      or by an individual or Legal Entity authorized to submit on behalf of
      the copyright owner. For the purposes of this definition, "submitted"
      means any form of electronic, verbal, or written communication sent
      to the Licensor or its representatives, including but not limited to
      communication on electronic mailing lists, source code control systems,
      and issue tracking systems that are managed by, or on behalf of, the
      Licensor for the purpose of discussing and improving the Work, but
      excluding communication that is conspicuously marked or otherwise
      designated in writing by the copyright owner as "Not a Contribution."

      "Contributor" shall mean Licensor and any individual or Legal Entity
      on behalf of whom a Contribution has been received by Licensor and
      subsequently incorporated within the Work.

   2. Grant of Copyright License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      copyright license to reproduce, prepare Derivative Works of,
      publicly display, publicly perform, sublicense, and distribute the
      Work and such Derivative Works in Source or Object form.

   3. Grant of Patent License. Subject to the terms and conditions of
      this License, each Contributor hereby grants to You a perpetual,
      worldwide, non-exclusive, no-charge, royalty-free, irrevocable
      (except as stated in this section) patent license to make, have made,
      use, offer to sell, sell, import, and otherwise transfer the Work,
      where such license applies only to those patent claims licensable
      by such Contributor that are necessarily infringed by their
      Contribution(s) alone or by combination of their Contribution(s)
      with the Work to which such Contribution(s) was submitted. If You
      institute patent litigation against any entity (including a
      cross-claim or counterclaim in a lawsuit) alleging that the Work
      or a Contribution incorporated within the Work constitutes direct
      or contributory patent infringement, then any patent licenses
      granted to You under this License for that Work shall terminate
      as of the date such litigation is filed.

   4. Redistribution. You may reproduce and distribute copies of the
      Work or Derivative Works thereof in any medium, with or without
      modifications, and in Source or Object form, provided that You
      meet the following conditions:

      (a) You must give any other recipients of the Work or
          Derivative Works a copy of this License; and

      (b) You must cause any modified files to carry prominent notices
          stating that You changed the files; and

      (c) You must retain, in the Source form of any Derivative Works
          that You distribute, all copyright, patent, trademark, and
          attribution notices from the Source form of the Work,
          excluding those notices that do not pertain to any part of
          the Derivative Works; and

      (d) If the Work includes a "NOTICE" text file as part of its
          distribution, then any Derivative Works that You distribute must
          include a readable copy of the attribution notices contained
          within such NOTICE file, excluding those notices that do not
          pertain to any part of the Derivative Works, in at least one
          of the following places: within a NOTICE text file distributed
          as part of the Derivative Works; within the Source form or
          documentation, if provided along with the Derivative Works; or,
          within a display generated by the Derivative Works, if and
          wherever such third-party notices normally appear. The contents
          of the NOTICE file are for informational purposes only and
          do not modify the License. You may add Your own attribution
          notices within Derivative Works that You distribute, alongside
          or as an addendum to the NOTICE text from the Work, provided
          that such additional attribution notices cannot be construed
          as modifying the License.

      You may add Your own copyright statement to Your modifications and
      may provide additional or different license terms and conditions
      for use, reproduction, or distribution of Your modifications, or
      for any such Derivative Works as a whole, provided Your use,
      reproduction, and distribution of the Work otherwise complies with
      the conditions stated in this License.

   5. Submission of Contributions. Unless You explicitly state otherwise,
      any Contribution intentionally submitted for inclusion in the Work
      by You to the Licensor shall be under the terms and conditions of
      this License, without any additional terms or conditions.
      Notwithstanding the above, nothing herein shall supersede or modify
      the terms of any separate license agreement you may have executed
      with Licensor regarding such Contributions.

   6. Trademarks. This License does not grant permission to use the trade
      names, trademarks, service marks, or product names of the Licensor,
      except as required for reasonable and customary use in describing the
      origin of the Work and reproducing the content of the NOTICE file.

   7. Disclaimer of Warranty. Unless required by applicable law or
      agreed to in writing, Licensor provides the Work (and each
      Contributor provides its Contributions) on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
      implied, including, without limitation, any warranties or conditions
      of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
      PARTICULAR PURPOSE. You are solely responsible for determining the
      appropriateness of using or redistributing the Work and assume any
      risks associated with Your exercise of permissions under this License.

   8. Limitation of Liability. In no event and under no legal theory,
      whether in tort (including negligence), contract, or otherwise,
      unless required by applicable law (such as deliberate and grossly
      negligent acts) or agreed to in writing, shall any Contributor be
      liable to You for damages, including any direct, indirect, special,
      incidental, or consequential damages of any character arising as a
      result of this License or out of the use or inability to use the
      Work (including but not limited to damages for loss of goodwill,
      work stoppage, computer failure or malfunction, or any and all
      other commercial damages or losses), even if such Contributor
      has been advised of the possibility of such damages.

   9. Accepting Warranty or Additional Liability. While redistributing
      the Work or Derivative Works thereof, You may choose to offer,
      and charge a fee for, acceptance of support, warranty, indemnity,
      or other liability obligations and/or rights consistent with this
      License. However, in accepting such obligations, You may act only
      on Your own behalf and on Your sole responsibility, not on behalf
      of any other Contributor, and only if You agree to indemnify,
      defend, and hold each Contributor harmless for any liability
      incurred by, or claims asserted against, such Contributor by reason
      of your accepting any such warranty or additional liability.

   END OF TERMS AND CONDITIONS

   APPENDIX: How to apply the Apache License to your work.

      To apply the Apache License to your work, attach the following
      boilerplate notice, with the fields enclosed by brackets "[]"
      replaced with your own identifying information. (Don't include
      the brackets!)  The text should be enclosed in the appropriate
      comment syntax for the file format. We also recommend that a
      file or class name and description of purpose be included on the
      same "printed page" as the copyright notice for easier
      identification within third-party archives.

   Copyright [yyyy] [name of copyright owner]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

</details>
