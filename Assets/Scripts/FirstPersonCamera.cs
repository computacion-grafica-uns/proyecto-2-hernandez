/*using UnityEngine;

/// <summary>
/// Cámara en primera persona para recorrer la Escena B.
/// Requiere un CharacterController en el mismo GameObject (evita atravesar paredes/objetos).
/// Controles:
///   W / Flecha arriba    -> avanzar
///   S / Flecha abajo     -> retroceder
///   A / Flecha izquierda -> girar a la izquierda
///   D / Flecha derecha   -> girar a la derecha
///   Mouse (opcional)     -> mirar alrededor (activar/desactivar con useMouseLook)
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class FirstPersonCamera : MonoBehaviour
{
    [Header("Movimiento")]
    public float moveSpeed = 5f;
    public float turnSpeed = 90f; // grados por segundo, usado por teclado (A/D)

    [Header("Mirada con mouse (opcional)")]
    public bool useMouseLook = true;
    public Transform cameraHead;   // si tenés un hijo con la Camera, arrastralo acá; si no, usa este mismo transform
    public float mouseSensitivity = 2f;
    public float pitchMin = -80f;
    public float pitchMax = 80f;

    [Header("Física simple")]
    public float gravity = -9.81f;

    private CharacterController controller;
    private float pitch = 0f;
    private Vector3 verticalVelocity;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        if (cameraHead == null) cameraHead = transform;

        if (useMouseLook)
            Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        HandleRotation();
        HandleMovement();

        if (Input.GetKeyDown(KeyCode.Escape))
            Cursor.lockState = Cursor.lockState == CursorLockMode.Locked
                ? CursorLockMode.None
                : CursorLockMode.Locked;
    }

    void HandleRotation()
    {
        // Giro horizontal con teclado (cumple el requisito explícito de la consigna)
        float keyboardTurn = Input.GetAxis("Horizontal") * turnSpeed * Time.deltaTime;
        transform.Rotate(Vector3.up * keyboardTurn);

        // Mirada libre opcional con mouse
        if (useMouseLook)
        {
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
            float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

            transform.Rotate(Vector3.up * mouseX);
            pitch = Mathf.Clamp(pitch - mouseY, pitchMin, pitchMax);
            cameraHead.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }
    }

    void HandleMovement()
    {
        // Avanzar / retroceder (Vertical = W/S o flechas arriba/abajo)
        float forwardInput = Input.GetAxis("Vertical");
        Vector3 move = transform.forward * forwardInput * moveSpeed;

        controller.Move(move * Time.deltaTime);

        // Gravedad simple para que no flote si el piso tiene desniveles
        if (controller.isGrounded && verticalVelocity.y < 0)
            verticalVelocity.y = -2f;
        verticalVelocity.y += gravity * Time.deltaTime;
        controller.Move(verticalVelocity * Time.deltaTime);
    }
}*/

using UnityEngine;

/// <summary>
/// Cámara en primera persona para recorrer la Escena B.
/// Requiere un CharacterController en el mismo GameObject (evita atravesar paredes/objetos).
/// Controles:
///   W / Flecha arriba    -> avanzar
///   S / Flecha abajo     -> retroceder
///   A / Flecha izquierda -> girar a la izquierda
///   D / Flecha derecha   -> girar a la derecha
///   Mouse (opcional)     -> mirar alrededor (activar/desactivar con useMouseLook)
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class FirstPersonCamera : MonoBehaviour
{
    [Header("Movimiento")]
    public float moveSpeed = 5f;
    public float turnSpeed = 90f; // grados por segundo, usado por teclado (A/D)

    [Header("Mirada con mouse (opcional)")]
    public bool useMouseLook = true;
    public Transform cameraHead;   // si tenés un hijo con la Camera, arrastralo acá; si no, usa este mismo transform
    public float mouseSensitivity = 2f;
    public float pitchMin = -80f;
    public float pitchMax = 80f;

    [Header("Física simple")]
    public float gravity = -9.81f;

    private CharacterController controller;
    private float pitch = 0f;
    private Vector3 verticalVelocity;

    void Start()
    {
        controller = GetComponent<CharacterController>();
        if (cameraHead == null) cameraHead = transform;

        if (useMouseLook)
            Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        HandleRotation();
        HandleMovement();

        if (Input.GetKeyDown(KeyCode.Escape))
            Cursor.lockState = Cursor.lockState == CursorLockMode.Locked
                ? CursorLockMode.None
                : CursorLockMode.Locked;
    }

    void HandleRotation()
    {
        // Giro horizontal con teclado: A/D o flechas izquierda/derecha
        // (uso KeyCode directo, no Input.GetAxis, para no depender de la
        // configuración de ejes del Input Manager del proyecto)
        float keyboardTurn = 0f;
        if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A)) keyboardTurn = -1f;
        if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D)) keyboardTurn = 1f;

        transform.Rotate(Vector3.up * keyboardTurn * turnSpeed * Time.deltaTime);

        // Mirada libre opcional con mouse (solo controla el "pitch", mirar arriba/abajo)
        if (useMouseLook)
        {
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
            float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

            transform.Rotate(Vector3.up * mouseX);
            pitch = Mathf.Clamp(pitch - mouseY, pitchMin, pitchMax);
            cameraHead.localRotation = Quaternion.Euler(pitch, 0f, 0f);
        }
    }

    void HandleMovement()
    {
        // Avanzar / retroceder: W/S o flechas arriba/abajo
        // (KeyCode directo en vez de Input.GetAxis("Vertical") para evitar
        // conflictos con configuraciones previas del Input Manager)
        float forwardInput = 0f;
        if (Input.GetKey(KeyCode.UpArrow) || Input.GetKey(KeyCode.W)) forwardInput = 1f;
        if (Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.S)) forwardInput = -1f;

        Vector3 move = transform.forward * forwardInput * moveSpeed;
        controller.Move(move * Time.deltaTime);

        // Gravedad simple para que no flote si el piso tiene desniveles
        if (controller.isGrounded && verticalVelocity.y < 0)
            verticalVelocity.y = -2f;
        verticalVelocity.y += gravity * Time.deltaTime;
        controller.Move(verticalVelocity * Time.deltaTime);
    }
}