using System;
using UnityEngine;

public class Enemy : MonoBehaviour {
    bool isDead, walkingRight;
    [SerializeField] float speed = 5f;

    void Awake() {
        isDead = false;
    }

    void Update() {
        if (isDead) {
            Destroy(gameObject);
            return;
        }
        Move();
        Tick();
    }

    void Move() {
        if (walkingRight) {
            transform.position += Vector3.right*(speed*Time.deltaTime);
        }
        else {
            transform.position += Vector3.left*(speed*Time.deltaTime);
        }
    }

    float currentTime;
    [SerializeField] float timeToChangeDirection = 2f;
    void Tick() {
        currentTime += Time.deltaTime;
        if (!(currentTime >= timeToChangeDirection)) return;
        walkingRight = !walkingRight;
        currentTime = 0;
    }
}
