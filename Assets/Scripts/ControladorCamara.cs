
/*using System.Collections.Generic;
using UnityEngine;

public class ControladorCamara : MonoBehaviour
{
    [Header("Sistemas de C�mara")]
    public GameObject camaraOrbitalObj;
    public GameObject jugadorFPSObj;
    public CamaraOrbital camaraOrbital;

    [Header("Configuraci�n de Escena")]
    public Vector3 centroEscena;
    public List<Transform> objetosDestacados = new List<Transform>();
    private int indiceActual = -1;

    void Start()
    {
        ActivarOrbital();
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C) && camaraOrbitalObj != null && jugadorFPSObj != null)
        {
            if (camaraOrbitalObj.activeSelf)
                ActivarFPS();
            else
                ActivarOrbital();
        }

        if (camaraOrbitalObj != null && camaraOrbitalObj.activeSelf && objetosDestacados.Count > 0)
        {
            if (Input.GetKeyDown(KeyCode.RightArrow))
            {
                indiceActual++;
                if (indiceActual >= objetosDestacados.Count) indiceActual = 0;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.LeftArrow))
            {
                indiceActual--;
                if (indiceActual < 0) indiceActual = objetosDestacados.Count - 1;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.Space))
            {
                indiceActual = -1;
                camaraOrbital.CambiarObjetivo(centroEscena, 15f); 
            }
        }
    }

    void ActivarOrbital()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(true);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(false);
        
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    void ActivarFPS()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(false);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(true);
        
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
}*/

//ESTE SIIIII
/*
using System.Collections.Generic;
using UnityEngine;

public class ControladorCamara : MonoBehaviour
{
    [Header("Sistemas de Cámara")]
    public GameObject camaraOrbitalObj;
    public GameObject jugadorFPSObj;
    public CamaraOrbital camaraOrbital; // Mantenemos la referencia para la lógica orbital

    [Header("Configuración de Escena")]
    public Vector3 centroEscena;
    public List<Transform> objetosDestacados = new List<Transform>();
    private int indiceActual = -1;

    void Start()
    {
        // Aseguramos un estado inicial claro
        ActivarOrbital();
    }

    void Update()
    {
        // 1. Cambiar de modo con 'C'
        if (Input.GetKeyDown(KeyCode.C) && camaraOrbitalObj != null && jugadorFPSObj != null)
        {
            if (camaraOrbitalObj.activeSelf)
                ActivarFPS();
            else
                ActivarOrbital();
        }

        // 2. Solo ejecutar inputs orbitales si la orbital ESTÁ ACTIVA
        if (camaraOrbitalObj != null && camaraOrbitalObj.activeSelf && objetosDestacados.Count > 0)
        {
            if (Input.GetKeyDown(KeyCode.RightArrow))
            {
                indiceActual++;
                if (indiceActual >= objetosDestacados.Count) indiceActual = 0;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.LeftArrow))
            {
                indiceActual--;
                if (indiceActual < 0) indiceActual = objetosDestacados.Count - 1;
                camaraOrbital.CambiarObjetivo(objetosDestacados[indiceActual].position, 4f);
            }

            if (Input.GetKeyDown(KeyCode.Space))
            {
                indiceActual = -1;
                camaraOrbital.CambiarObjetivo(centroEscena, 15f); 
            }
        }
    }

    void ActivarOrbital()
    {
        // Activamos la orbital, apagamos FPS
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(true);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(false);
        
        // --- CONTROL DEL MOUSE PARA MODO ORBITAL ---
        Cursor.lockState = CursorLockMode.None; // Cursor libre
        Cursor.visible = true; // Cursor visible
    }

    void ActivarFPS()
    {
        // Apagamos la orbital, activamos FPS
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(false);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(true);
        
        // --- CONTROL DEL MOUSE PARA MODO FPS ---
        Cursor.lockState = CursorLockMode.Locked; // Cursor atrapado en el centro
        Cursor.visible = false; // Cursor invisible
    }
}*/

using System.Collections.Generic;
using UnityEngine;

public class ControladorCamara : MonoBehaviour
{
    [Header("Sistemas de Cámara")]
    public GameObject camaraOrbitalObj;
    public GameObject jugadorFPSObj;
    public CamaraOrbital camaraOrbital;

    [Header("Configuración de Escena")]
    public Vector3 centroEscena;
    public List<Transform> objetosDestacados = new List<Transform>();

    void Start()
    {
        ActivarOrbital();
    }

    void Update()
    {
        // 1. Cambiar entre modos con la tecla 'C'
        if (Input.GetKeyDown(KeyCode.C) && camaraOrbitalObj != null && jugadorFPSObj != null)
        {
            if (camaraOrbitalObj.activeSelf)
                ActivarFPS();
            else
                ActivarOrbital();
        }

        // 2. DETECTAR NÚMEROS (1 al 9) - Funciona para AMBOS modos
        for (int i = 1; i <= 9; i++)
        {
            // Revisa si presionaste el número de arriba (Alpha) o el del teclado numérico (Keypad)
            if (Input.GetKeyDown(KeyCode.Alpha0 + i) || Input.GetKeyDown(KeyCode.Keypad0 + i))
            {
                EnfocarObjetoPorIndice(i - 1); // Restamos 1 porque las listas en código empiezan en 0
            }
        }

        // 3. BARRA ESPACIADORA: Resetear vista (Solo en modo Orbital)
        if (Input.GetKeyDown(KeyCode.Space) && camaraOrbitalObj != null && camaraOrbitalObj.activeSelf)
        {
            camaraOrbital.CambiarObjetivo(centroEscena, 15f); 
        }
    }

    void EnfocarObjetoPorIndice(int indice)
    {
        // Validamos que el objeto exista en tu lista del Inspector
        if (indice < 0 || indice >= objetosDestacados.Count || objetosDestacados[indice] == null) return;

        Vector3 posicionObjetivo = objetosDestacados[indice].position;

        // ACCIÓN SI LA ORBITAL ESTÁ ACTIVA
        if (camaraOrbitalObj != null && camaraOrbitalObj.activeSelf)
        {
            camaraOrbital.CambiarObjetivo(posicionObjetivo, 4f);
        }
        // ACCIÓN SI LA PRIMERA PERSONA ESTÁ ACTIVA
        else if (jugadorFPSObj != null && jugadorFPSObj.activeSelf)
        {
            // Te teletransporta un poco hacia atrás y arriba del objeto para que no quedes "adentro" de él
            Vector3 posicionDestinoFPS = posicionObjetivo - (objetosDestacados[indice].forward * 2f) + (Vector3.up * 0.5f);
            jugadorFPSObj.transform.position = posicionDestinoFPS;
            
            // Hace que mires directamente al objeto destacado
            if (jugadorFPSObj.TryGetComponent<CamaraPrimeraPersona>(out var fpsScript))
            {
                jugadorFPSObj.transform.LookAt(posicionObjetivo);
                // Reseteamos el script de primera persona para que no "salte" la mirada al mover el mouse
                fpsScript.SendMessage("Start", SendMessageOptions.DontRequireReceiver);
            }
        }
    }

    void ActivarOrbital()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(true);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(false);
        
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    void ActivarFPS()
    {
        if (camaraOrbitalObj != null) camaraOrbitalObj.SetActive(false);
        if (jugadorFPSObj != null) jugadorFPSObj.SetActive(true);
        
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
}