using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CamaraFPSA : MonoBehaviour

{
    [Header("Movimiento libre")]
    public float velocidad = 5f;
    public float sensibilidad = 2f;

    private float rotX = 0f;
    private bool enfocada = false; // true = mirando una tetera, false = libre

    void Update()
    {
        if (enfocada) return; // si está enfocando una tetera no se mueve

        // Movimiento WASD
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        transform.Translate(new Vector3(h, 0, v) * velocidad * Time.deltaTime);

        // Subir y bajar con Q/E
        if (Input.GetKey(KeyCode.E))
            transform.Translate(Vector3.up * velocidad * Time.deltaTime);
        if (Input.GetKey(KeyCode.Q))
            transform.Translate(Vector3.down * velocidad * Time.deltaTime);

        // Rotación con click derecho
        if (Input.GetMouseButton(1))
        {
            float mouseX = Input.GetAxis("Mouse X") * sensibilidad;
            float mouseY = Input.GetAxis("Mouse Y") * sensibilidad;

            rotX -= mouseY;
            rotX = Mathf.Clamp(rotX, -80f, 80f);

            transform.localEulerAngles = new Vector3(rotX, transform.localEulerAngles.y + mouseX, 0);
        }
    }

    // Llamado desde CameraManager al cambiar a FPS
    public void Teleportar(Vector3 posicion, Vector3 mirarHacia)
    {
        enfocada = false;
        transform.position = posicion;
        transform.LookAt(mirarHacia);
        rotX = transform.localEulerAngles.x;
    }

    // Llamado desde CameraManager al enfocar una tetera con flechas
    public void EnfocarObjetivo(Vector3 posicion, Vector3 mirarHacia)
    {
        enfocada = true;
        transform.position = posicion;
        transform.LookAt(mirarHacia);
        rotX = transform.localEulerAngles.x;
    }

    // Llamado desde CameraManager al apretar Space en modo FPS
    public void ModoLibre()
    {
        enfocada = false;
    }
}
