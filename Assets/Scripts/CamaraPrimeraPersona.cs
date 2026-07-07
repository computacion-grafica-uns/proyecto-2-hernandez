/*using UnityEngine;

public class CamaraPrimeraPersona : MonoBehaviour
{
    [Header("Movimiento")]
    public float velocidadCaminar = 5f;
    public float velocidadCorrer = 10f;

    [Header("Mirada")]
    public float sensibilidadMouse = 2f;
    public Transform camaraTransform;

    private float rotacionX = 0f;

    void Update()
    {
        float mouseX = Input.GetAxis("Mouse X") * sensibilidadMouse;
        float mouseY = Input.GetAxis("Mouse Y") * sensibilidadMouse;

        rotacionX -= mouseY;
        rotacionX = Mathf.Clamp(rotacionX, -90f, 90f);

        camaraTransform.localRotation = Quaternion.Euler(rotacionX, 0f, 0f);
        transform.Rotate(Vector3.up * mouseX);

        float velocidadActual = Input.GetKey(KeyCode.LeftShift) ? velocidadCorrer : velocidadCaminar;
        
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        Vector3 movimiento = transform.right * x + transform.forward * z;
        transform.position += movimiento * velocidadActual * Time.deltaTime;
    }
}*/

using UnityEngine;

public class CamaraPrimeraPersona : MonoBehaviour
{
    [Header("Movimiento")]
    public float velocidadCaminar = 5f;
    public float velocidadCorrer = 10f;

    [Header("Mirada")]
    public float sensibilidadMouse = 2f;
    public Transform camaraTransform;

    private float rotacionX = 0f; // Para mirar arriba y abajo
    private float rotacionY = 0f; // Para mirar a los costados

    void Start()
    {
        // Tomamos la rotación inicial que tenga el objeto en la escena
        Vector3 rotacionInicial = transform.localEulerAngles;
        rotacionY = rotacionInicial.y;
        rotacionX = rotacionInicial.x;
    }

    void Update()
    {
        // 1. LEER MOVIMIENTO DEL MOUSE
        float mouseX = Input.GetAxis("Mouse X") * sensibilidadMouse;
        float mouseY = Input.GetAxis("Mouse Y") * sensibilidadMouse;

        // Calcular rotación vertical (Arriba/Abajo) y limitarla
        rotacionX -= mouseY;
        rotacionX = Mathf.Clamp(rotacionX, -90f, 90f);

        // Calcular rotación horizontal (Izquierda/Derecha) libre
        rotacionY += mouseX;

        // 2. APLICAR ROTACIÓN UNIFICADA
        // Si el objeto y el camaraTransform son el mismo, aplicamos ambas rotaciones juntas
        if (camaraTransform == transform)
        {
            transform.localRotation = Quaternion.Euler(rotacionX, rotacionY, 0f);
        }
        else
        {
            // Por si en el futuro separás la cámara del cuerpo:
            camaraTransform.localRotation = Quaternion.Euler(rotacionX, 0f, 0f);
            transform.localRotation = Quaternion.Euler(0f, rotacionY, 0f);
        }

        // 3. MOVIMIENTO (WASD / FLECHAS)
        float velocidadActual = Input.GetKey(KeyCode.LeftShift) ? velocidadCorrer : velocidadCaminar;
        
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");

        // Calculamos el movimiento relativo a hacia dónde está mirando el objeto actualmente
        Vector3 movimiento = transform.right * x + transform.forward * z;
        transform.position += movimiento * velocidadActual * Time.deltaTime;
    }
}