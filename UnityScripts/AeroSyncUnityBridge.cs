using UnityEngine;
using System.Net;
using System.Net.Sockets;
using System.Text;

/// <summary>
/// AeroSyncUnityBridge sends a signal to the AeroSync Flutter application
/// over UDP to trigger wind simulations synchronized with the VR game.
/// This script should be attached to a GameObject in your Unity scene.
/// </summary>
public class AeroSyncUnityBridge : MonoBehaviour
{
    // --------------------------------------------------------
    // Public Configuration Properties (Editable in Unity Inspector)
    // --------------------------------------------------------

    [Header("AeroSync Configuration")]
    [Tooltip("Unique ID for this game/scene. Must match the 'Linked Game ID' in AeroSync.")]
    // This ID is sent in the network payload so the Flutter app knows which project is starting.
    public string projectId = "EagleFlight01";

    [Tooltip("IP Address of the machine running AeroSync. 255.255.255.255 will broadcast to the local network.")]
    // The target IP address where the UDP packet will be sent. 
    // Using 255.255.255.255 ensures all devices on the local subnet receive it.
    public string targetIP = "255.255.255.255";

    [Tooltip("UDP Port AeroSync is listening on (default 8052).")]
    // The specific network port that the Flutter application is listening to.
    public int targetPort = 8052;

    [Header("Debug")]
    [Tooltip("If true, prints a debug message to the console exactly when the signal is sent.")]
    // Toggle for debug logging in the Unity console to help with troubleshooting.
    public bool enableDebugLogging = true;

    // --------------------------------------------------------
    // Private Variables
    // --------------------------------------------------------

    // UDP Client instance used to send network packets.
    private UdpClient _udpClient;

    // --------------------------------------------------------
    // Unity Lifecycle Methods
    // --------------------------------------------------------

    /// <summary>
    /// Unity's Awake method is called when the script instance is being loaded.
    /// Used here to initialize the UDP client before the game fully starts.
    /// </summary>
    private void Awake()
    {
        // Initialize a new UdpClient instance
        _udpClient = new UdpClient();
        
        // If we are using the broadcast IP address, we must explicitly enable
        // the EnableBroadcast property on the UDP client to allow sending broadcast packets.
        if (targetIP == "255.255.255.255")
        {
            _udpClient.EnableBroadcast = true;
        }
    }

    /// <summary>
    /// Call this method (e.g., from an event or StartFlight) to trigger the wind sim in AeroSync.
    /// This is the main function you would link to a UI Button or a specific game event trigger.
    /// </summary>
    public void TriggerSync()
    {
        if (enableDebugLogging)
        {
            Debug.Log($"[AeroSyncUnityBridge] Sending GAME_START signal to AeroSync at {targetIP}:{targetPort} for Project ID: {projectId}");
        }

        try
        {
            // Create a JSON formatted string payload containing the action type and project ID.
            // This is the data format expected by the AeroSync Flutter application.
            string jsonPayload = $"{{\"action\":\"GAME_START\",\"projectId\":\"{projectId}\"}}";
            
            // Convert the JSON string payload into a byte array (required for UDP transmission)
            byte[] bytes = Encoding.UTF8.GetBytes(jsonPayload);

            // Define the network endpoint (IP Address and Port combination) where the packet should be delivered
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Parse(targetIP), targetPort);
            
            // Send the byte array over UDP to the specified endpoint
            _udpClient.Send(bytes, bytes.Length, endPoint);
        }
        catch (System.Exception ex)
        {
            // Catch and log any network or parsing exceptions so they don't crash the game
            Debug.LogError($"[AeroSyncUnityBridge] Failed to send trigger to AeroSync: {ex.Message}");
        }
    }

    /// <summary>
    /// Unity's OnDestroy method is called when the MonoBehaviour will be destroyed.
    /// It is important to clean up network resources here to prevent memory leaks or locked ports.
    /// </summary>
    private void OnDestroy()
    {
        // Ensure the UDP client is properly closed when this script or object is destroyed
        if (_udpClient != null)
        {
            _udpClient.Close();
        }
    }
}
