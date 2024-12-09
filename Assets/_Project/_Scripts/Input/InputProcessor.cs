using System;
using UnityEngine;
using UnityEngine.InputSystem;


[CreateAssetMenu(menuName = "Input/Input Processor")]
public class InputProcessor : ScriptableObject, PlayerInput.IPlayerActions {
    PlayerInput playerInput;
    
    public event Action<Vector2> OnMoveEvent = delegate { };
    public event Action OnJumpEvent = delegate { };
    
    public void Enable() {
        playerInput = new();
        playerInput.Player.SetCallbacks(this);
        playerInput.Player.Enable();
    }

    public void OnMove(InputAction.CallbackContext context) {
        OnMoveEvent.Invoke(context.ReadValue<Vector2>());
    }
    public void OnJump(InputAction.CallbackContext context) {
        if (context.phase != InputActionPhase.Performed) return;
        OnJumpEvent.Invoke();
    }
}