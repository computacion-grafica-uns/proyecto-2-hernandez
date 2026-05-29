using UnityEngine;

public class COB : MonoBehaviour
{
    [Header("Objetivo y Posicionamiento")]
    public Vector3 objetivo;
    public float distancia = 80f;

    [Header("Limites de Zoom")]
    public float minDistancia = 2f;
    public float maxDistancia = 500f;

    [Header("Sensibilidad")]
    public float sensibilidadRotacion = 3f;
    public float sensibilidadZoom     = 10f;

    private float anguloX = 45f;
    private float anguloY = 50f;

    void Update()
    {
        // Rotacion con click derecho
        if (Input.GetMouseButton(1))
        {
            anguloX += Input.GetAxis("Mouse X") * sensibilidadRotacion;
            anguloY -= Input.GetAxis("Mouse Y") * sensibilidadRotacion;
        }

        anguloY = Mathf.Clamp(anguloY, 10f, 80f);

        // Zoom con rueda
        float scroll = Input.GetAxis("Mouse ScrollWheel");
        distancia -= scroll * sensibilidadZoom;
        distancia = Mathf.Clamp(distancia, minDistancia, maxDistancia);

        // Calcular posicion orbital
        Quaternion rotacion = Quaternion.Euler(anguloY, anguloX, 0);
        Vector3    offset   = rotacion * new Vector3(0, 0, -distancia);

        transform.position = objetivo + offset;
        transform.LookAt(objetivo);
    }

    public void CambiarObjetivo(Vector3 nuevoObjetivo, float nuevaDistancia)
    {
        objetivo  = nuevoObjetivo;
        distancia = nuevaDistancia;
    }
}
