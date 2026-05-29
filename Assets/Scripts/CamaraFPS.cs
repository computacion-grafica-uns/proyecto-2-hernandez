using UnityEngine;

public class CamaraFPS : MonoBehaviour
{
    [Header("Movimiento")]
    public float velocidad    = 5f;
    public float sensibilidad = 2f;

    private float rotX = 0f;

    void Update()
    {
        // Movimiento WASD / flechas
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        transform.Translate(new Vector3(h, 0, v) * velocidad * Time.deltaTime);

        // Subir / bajar con E / Q
        if (Input.GetKey(KeyCode.E))
            transform.Translate(Vector3.up   * velocidad * Time.deltaTime);
        if (Input.GetKey(KeyCode.Q))
            transform.Translate(Vector3.down * velocidad * Time.deltaTime);

        // Rotacion con click derecho
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X") * sensibilidad;
            float mouseY = Input.GetAxis("Mouse Y") * sensibilidad;

            rotX -= mouseY;
            rotX  = Mathf.Clamp(rotX, -80f, 80f);

            transform.localEulerAngles = new Vector3(rotX,
                                                     transform.localEulerAngles.y + mouseX,
                                                     0);
        }
    }

    // Llamado por CameraManagerB al activar modo FPS
    public void Teleportar(Vector3 posicion, Vector3 mirarHacia)
    {
        transform.position = posicion;
        transform.LookAt(mirarHacia);
        // Sincronizar rotX con el angulo actual para que no salte
        float angulo = transform.localEulerAngles.x;
        rotX = angulo > 180f ? angulo - 360f : angulo;
    }
}
