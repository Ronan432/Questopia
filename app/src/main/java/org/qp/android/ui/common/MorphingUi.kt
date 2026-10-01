package org.qp.android.ui.common

import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.CornerSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Calculates standard Material 3 Expressive grouped container shape based on item index.
 */
fun getGroupedItemShape(
    index: Int,
    total: Int,
    outerRadius: Dp = 24.dp,
    innerRadius: Dp = 4.dp
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
 * Remembers a smoothly animated shape that morphs from restingShape to pressedRadius on press.
 */
@Composable
fun rememberMorphingShape(
    isPressed: Boolean,
    restingShape: Shape = RoundedCornerShape(16.dp),
    pressedRadius: Dp = 26.dp
): Shape {
    val density = LocalDensity.current
    val resting = restingShape as? RoundedCornerShape

    fun CornerSize?.toDp(): Dp = this?.toPx(Size(1000f, 1000f), density)?.let { (it / density.density).dp } ?: 16.dp

    val animTopStart by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else resting?.topStart.toDp(),
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "morphTS"
    )
    val animTopEnd by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else resting?.topEnd.toDp(),
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "morphTE"
    )
    val animBottomStart by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else resting?.bottomStart.toDp(),
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "morphBS"
    )
    val animBottomEnd by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else resting?.bottomEnd.toDp(),
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy, stiffness = Spring.StiffnessLow),
        label = "morphBE"
    )

    return RoundedCornerShape(
        topStart = animTopStart.coerceAtLeast(0.dp),
        topEnd = animTopEnd.coerceAtLeast(0.dp),
        bottomStart = animBottomStart.coerceAtLeast(0.dp),
        bottomEnd = animBottomEnd.coerceAtLeast(0.dp)
    )
}

/**
 * Interactive surface with built-in spring corner morphing and haptics.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MorphingSurface(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(16.dp),
    color: Color = MaterialTheme.colorScheme.surfaceContainer,
    contentColor: Color = MaterialTheme.colorScheme.onSurface,
    tonalElevation: Dp = 0.dp,
    border: BorderStroke? = null,
    pressedRadius: Dp = 26.dp,
    onClick: (() -> Unit)? = null,
    onLongClick: (() -> Unit)? = null,
    content: @Composable () -> Unit
) {
    val view = LocalView.current
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val activeShape = rememberMorphingShape(isPressed, shape, pressedRadius)

    Surface(
        shape = activeShape,
        color = color,
        contentColor = contentColor,
        tonalElevation = tonalElevation,
        border = border,
        modifier = modifier
            .clip(activeShape)
            .then(
                if (onClick != null || onLongClick != null) {
                    Modifier.combinedClickable(
                        interactionSource = interactionSource,
                        indication = null,
                        onClick = {
                            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
                            onClick?.invoke()
                        },
                        onLongClick = onLongClick?.let { action ->
                            {
                                view.performHapticFeedback(HapticFeedbackConstants.LONG_PRESS)
                                action()
                            }
                        }
                    )
                } else Modifier
            )
    ) {
        content()
    }
}

/**
 * Standard Morphing Action Button with expressive spring feedback.
 */
@Composable
fun MorphingButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isTonal: Boolean = false,
    restingRadius: Dp = 24.dp,
    pressedRadius: Dp = 8.dp,
    content: @Composable RowScope.() -> Unit
) {
    val view = LocalView.current
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val cornerRadius by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else restingRadius,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "btnCornerMorph"
    )

    val shape = RoundedCornerShape(cornerRadius.coerceAtLeast(0.dp))
    val hapticClick = {
        view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
        onClick()
    }

    if (isTonal) {
        FilledTonalButton(
            onClick = hapticClick,
            enabled = enabled,
            shape = shape,
            interactionSource = interactionSource,
            modifier = modifier,
            content = content
        )
    } else {
        Button(
            onClick = hapticClick,
            enabled = enabled,
            shape = shape,
            interactionSource = interactionSource,
            modifier = modifier,
            content = content
        )
    }
}

/**
 * Outlined variant of the Morphing Button.
 */
@Composable
fun MorphingOutlinedButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    restingRadius: Dp = 24.dp,
    pressedRadius: Dp = 8.dp,
    content: @Composable RowScope.() -> Unit
) {
    val view = LocalView.current
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val cornerRadius by animateDpAsState(
        targetValue = if (isPressed) pressedRadius else restingRadius,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "outlinedBtnCornerMorph"
    )

    OutlinedButton(
        onClick = {
            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
            onClick()
        },
        enabled = enabled,
        shape = RoundedCornerShape(cornerRadius.coerceAtLeast(0.dp)),
        interactionSource = interactionSource,
        modifier = modifier,
        content = content
    )
}

/**
 * Morphing button specifically styled for dialog confirmation/cancellation.
 */
@Composable
fun MorphingDialogButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isOutlined: Boolean = false,
    content: @Composable RowScope.() -> Unit
) {
    if (isOutlined) {
        MorphingOutlinedButton(
            onClick = onClick,
            modifier = modifier,
            enabled = enabled,
            content = content
        )
    } else {
        MorphingButton(
            onClick = onClick,
            modifier = modifier,
            enabled = enabled,
            content = content
        )
    }
}

/**
 * Expressive spring-animated drawer handle for ModalBottomSheet.
 */
@Composable
fun CustomDrawerHandle(
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()

    val scale by animateFloatAsState(
        targetValue = if (isPressed) 1.35f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "drawerHandleScale"
    )

    val widthDp by animateDpAsState(
        targetValue = if (isPressed) 48.dp else 32.dp,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "drawerHandleWidth"
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .width(widthDp)
                .height(4.dp)
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                }
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f))
                .clickable(
                    interactionSource = interactionSource,
                    indication = null,
                    onClick = {}
                )
        )
    }
}
