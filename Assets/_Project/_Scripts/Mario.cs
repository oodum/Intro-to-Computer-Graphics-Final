using System;
using System.Threading.Tasks;
using UnityEngine;
public class Mario : MonoBehaviour {
    [SerializeField] InputProcessor input;
    [SerializeField] float speed = 5f;

    [SerializeField] Material normalMaterial, hitMaterial;
    [SerializeField] float hitDuration;

    [SerializeField] Renderer meshRenderer;

    bool invulnerable = false;
    Rigidbody rb;

    void Awake() {
        rb = GetComponent<Rigidbody>();
    }
    void OnEnable() {
        input.OnMoveEvent += Move;
        input.OnJumpEvent += Jump;
    }

    void OnDisable() {
        input.OnMoveEvent -= Move;
        input.OnJumpEvent -= Jump;
    }

    void Start() {
        input.Enable();
    }

    void Move(Vector2 direction) {
        rb.AddForce(new Vector3(direction.x, 0, direction.y)*speed, ForceMode.Force);
    }

    void Jump() {
        rb.AddForce(Vector3.up*5, ForceMode.Impulse);
        _ = Spin();
    }

    async Task Hit() {
        meshRenderer.material = hitMaterial;
        await Awaitable.WaitForSecondsAsync(hitDuration);
        meshRenderer.material = normalMaterial;
    }

    async Task Spin() {
        float currentTime = 0;
        invulnerable = true;
        while (currentTime <= 1) {
            transform.Rotate(Vector3.up, 360*Time.deltaTime);
            currentTime += Time.deltaTime;
            await Awaitable.NextFrameAsync();
        }
        invulnerable = false;
    }
    
    void OnCollisionEnter(Collision other) {
        if (!other.gameObject.CompareTag("Enemy")) return;
        if (invulnerable) Destroy(other.gameObject);
        else _ = Hit();
    }
}
