package org.qp.desktop.ui.common

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

fun getGroupedItemShape(
    index: Int,
    total: Int,
    outerRadius: Dp = 24.dp,
    innerRadius: Dp = 6.dp
): RoundedCornerShape = when {
    total <= 1 -> RoundedCornerShape(outerRadius)
    index == 0 -> RoundedCornerShape(
        topStart = outerRadius,
        topEnd = outerRadius,
        bottomStart = innerRadius,
        bottomEnd = innerRadius
    )
    index == total - 1 -> RoundedCornerShape(
        topStart = innerRadius,
        topEnd = innerRadius,
        bottomStart = outerRadius,
        bottomEnd = outerRadius
    )
    else -> RoundedCornerShape(innerRadius)
}

/**
 * Dynamically morphs shape corner radii on press with spring physics.
 */
@Composable
fun rememberMorphingShape(
    isPressed: Boolean,
    restingCorner: Dp = 20.dp,
    pressedCorner: Dp = 32.dp
): Shape {
    val cornerAnim by animateDpAsState(
        targetValue = if (isPressed) pressedCorner else restingCorner,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "morphRadius"
    )
    return RoundedCornerShape(cornerAnim.coerceAtLeast(0.dp))
}

@Composable
fun DesktopMorphingSurface(
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    shape: Shape? = null,
    restingCorner: Dp = 20.dp,
    pressedCorner: Dp = 32.dp,
    color: Color = Color.Transparent,
    enabled: Boolean = true,
    content: @Composable () -> Unit
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val morphShape = if (shape != null) {
        shape
    } else {
        rememberMorphingShape(
            isPressed = isPressed && enabled && onClick != null,
            restingCorner = restingCorner,
            pressedCorner = pressedCorner
        )
    }

    val scale by animateFloatAsState(
        targetValue = if (isPressed && enabled && onClick != null) 0.975f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessMedium),
        label = "pressScale"
    )

    Surface(
        modifier = modifier
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
            }
            .clip(morphShape)
            .then(
                if (onClick != null) {
                    Modifier.clickable(
                        interactionSource = interactionSource,
                        indication = null,
                        enabled = enabled,
                        onClick = onClick
                    )
                } else Modifier
            ),
        shape = morphShape,
        color = color
    ) {
        content()
    }
}
