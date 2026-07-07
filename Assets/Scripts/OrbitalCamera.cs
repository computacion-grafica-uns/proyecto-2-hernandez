using UnityEngine;
/*

/// <summary>
/// Cámara orbital: rota alrededor de un "target" (punto de foco) y permite hacer zoom.
/// El target puede ser el centro de toda la escena o un objeto puntual,
/// eso lo controla CameraManager llamando a SetTarget().
/// </summary>
public class OrbitalCamera : MonoBehaviour
{
    [Header("Objetivo actual")]
    public Transform target;
    public float distance = 10f;

    [Header("Límites de zoom")]
    public float minDistance = 1.5f;
    public float maxDistance = 60f;

    [Header("Rotación")]
    public float rotationSpeed = 150f;
    public float zoomSpeed = 10f;
    public float yMinLimit = -20f;
    public float yMaxLimit = 80f;

    [Header("Suavizado (opcional)")]
    public float smoothTime = 0.05f;

    private float x, y;
    private float currentDistance;
    private float distanceVelocity;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;
        x = angles.y;
        y = angles.x;
        currentDistance = distance;
    }

    void LateUpdate()
    {
        if (target == null) return;

        // Rotar manteniendo presionado el botón derecho del mouse
        if (Input.GetMouseButton(1))
        {
            x += Input.GetAxis("Mouse X") * rotationSpeed * Time.deltaTime;
            y -= Input.GetAxis("Mouse Y") * rotationSpeed * Time.deltaTime;
            y = ClampAngle(y, yMinLimit, yMaxLimit);
        }

        // Zoom con la rueda del mouse
        distance -= Input.GetAxis("Mouse ScrollWheel") * zoomSpeed;
        distance = Mathf.Clamp(distance, minDistance, maxDistance);
        currentDistance = Mathf.SmoothDamp(currentDistance, distance, ref distanceVelocity, smoothTime);

        Quaternion rotation = Quaternion.Euler(y, x, 0);
        Vector3 position = rotation * new Vector3(0f, 0f, -currentDistance) + target.position;

        transform.rotation = rotation;
        transform.position = position;
    }

    float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360f) angle += 360f;
        if (angle > 360f) angle -= 360f;
        return Mathf.Clamp(angle, min, max);
    }

    /// <summary>
    /// Cambia el punto de foco de la cámara (toda la escena u objeto puntual)
    /// y ajusta la distancia para que se vea bien encuadrado.
    /// </summary>
    public void SetTarget(Transform newTarget, float newDistance)
    {
        target = newTarget;
        distance = Mathf.Clamp(newDistance, minDistance, maxDistance);
    }
}
*/

using UnityEngine;

/// <summary>
/// Cámara orbital: rota alrededor de un "target" (punto de foco) y permite hacer zoom.
/// El target puede ser el centro de toda la escena o un objeto puntual,
/// eso lo controla CameraManager llamando a SetTarget().
/// </summary>
public class OrbitalCamera : MonoBehaviour
{
    [Header("Objetivo actual")]
    public Transform target;
    public float distance = 10f;

    [Header("Límites de zoom")]
    public float minDistance = 1.5f;
    public float maxDistance = 60f;

    [Header("Rotación")]
    public float rotationSpeed = 150f;
    public float zoomSpeed = 10f;
    public float yMinLimit = -20f;
    public float yMaxLimit = 80f;

    [Header("Suavizado (opcional)")]
    public float smoothTime = 0.05f;

    private float x, y;
    private float currentDistance;
    private float distanceVelocity;

    void Start()
    {
        Vector3 angles = transform.eulerAngles;
        x = angles.y;
        y = angles.x;
        currentDistance = distance;
    }

    void LateUpdate()
    {
        if (target == null) return;

        // Rotar manteniendo presionado el botón derecho del mouse
        if (Input.GetMouseButton(1))
        {
            x += Input.GetAxis("Mouse X") * rotationSpeed * Time.deltaTime;
            y -= Input.GetAxis("Mouse Y") * rotationSpeed * Time.deltaTime;
            y = ClampAngle(y, yMinLimit, yMaxLimit);
        }

        // Rotar también con las flechas del teclado (alternativa al mouse)
        float keyboardX = Input.GetAxis("Horizontal") * rotationSpeed * Time.deltaTime;
        float keyboardY = Input.GetAxis("Vertical") * rotationSpeed * Time.deltaTime;
        x += keyboardX;
        y = ClampAngle(y - keyboardY, yMinLimit, yMaxLimit);

        // Zoom con la rueda del mouse
        distance -= Input.GetAxis("Mouse ScrollWheel") * zoomSpeed;
        distance = Mathf.Clamp(distance, minDistance, maxDistance);
        currentDistance = Mathf.SmoothDamp(currentDistance, distance, ref distanceVelocity, smoothTime);

        Quaternion rotation = Quaternion.Euler(y, x, 0);
        Vector3 position = rotation * new Vector3(0f, 0f, -currentDistance) + target.position;

        transform.rotation = rotation;
        transform.position = position;
    }

    float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360f) angle += 360f;
        if (angle > 360f) angle -= 360f;
        return Mathf.Clamp(angle, min, max);
    }

    /// <summary>
    /// Cambia el punto de foco de la cámara (toda la escena u objeto puntual)
    /// y ajusta la distancia para que se vea bien encuadrado.
    /// </summary>
    public void SetTarget(Transform newTarget, float newDistance)
    {
        target = newTarget;
        distance = Mathf.Clamp(newDistance, minDistance, maxDistance);
    }
}